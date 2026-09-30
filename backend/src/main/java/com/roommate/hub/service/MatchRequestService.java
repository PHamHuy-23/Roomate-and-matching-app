package com.roommate.hub.service;

import com.roommate.hub.dto.MatchRequestResponseDTO;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.roommate.hub.exception.ForbiddenException;

import com.roommate.hub.exception.ResourceNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchRequestService {

    private final MatchRequestRepository matchRequestRepository;
    private final UserRepository userRepository;
    private final MatchingService matchingService;
    private final com.roommate.hub.repository.BlockedUserRepository blockedUserRepository;

    @Transactional
    public MatchRequestResponseDTO sendRequest(Long senderId, Long receiverId) {
        if (senderId.equals(receiverId)) {
            throw new RuntimeException("Không thể tự ghép đôi với chính mình!");
        }

        Long firstId = Math.min(senderId, receiverId);
        Long secondId = Math.max(senderId, receiverId);

        // Khóa bi-directional theo thứ tự ID tăng dần để ngăn race condition và loại trừ deadlock
        userRepository.findByIdForUpdate(firstId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + firstId));
        userRepository.findByIdForUpdate(secondId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + secondId));

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Sender not found: " + senderId));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new ResourceNotFoundException("Receiver not found: " + receiverId));
        requireConnectable(sender, receiver);

        Double score = matchingService.getRecommendations(sender).stream()
                .filter(recommendation -> receiverId.equals(recommendation.getUserId()))
                .map(recommendation -> recommendation.getTotalScore())
                .findFirst().orElse(0.0);

        MatchRequest request = matchRequestRepository.findConnectionBetweenUsers(senderId, receiverId)
                .map(existing -> {
                    if (existing.getStatus() == MatchRequest.MatchStatus.REJECTED) {
                        existing.setSender(sender);
                        existing.setReceiver(receiver);
                        existing.setStatus(MatchRequest.MatchStatus.PENDING);
                        existing.setMatchScore(score);
                        existing.setCreatedAt(LocalDateTime.now());
                        return matchRequestRepository.save(existing);
                    }
                    if (existing.getStatus() == MatchRequest.MatchStatus.PENDING
                            && !existing.getSender().getId().equals(senderId)) {
                        existing.setStatus(MatchRequest.MatchStatus.ACCEPTED);
                        if (existing.getMatchScore() == null || existing.getMatchScore() == 0.0) {
                            existing.setMatchScore(score);
                        }
                        return matchRequestRepository.save(existing);
                    }
                    return existing;
                })
                .orElseGet(() -> matchRequestRepository.save(MatchRequest.builder()
                        .sender(sender)
                        .receiver(receiver)
                        .matchScore(score)
                        .status(MatchRequest.MatchStatus.PENDING)
                        .build()));

        boolean isAccepted = request.getStatus() == MatchRequest.MatchStatus.ACCEPTED;
        return buildResponse(request, receiver, isAccepted);
    }

    private MatchRequestResponseDTO buildResponse(MatchRequest request, User partner, boolean isAccepted) {
        return MatchRequestResponseDTO.builder()
                .requestId(request.getId())
                .partnerId(partner.getId())
                .partnerName(partner.getFullName())
                .partnerAvatar(partner.getAvatarUrl())
                .matchScore(request.getMatchScore())
                .status(request.getStatus().name())
                .createdAt(request.getCreatedAt())
                .contactPhone(isAccepted ? partner.getPhone() : null)
                .contactEmail(isAccepted ? partner.getEmail() : null)
                .build();
    }

    @Transactional
    public Map<String, Object> respondRequest(Long requestId, boolean isAccepted, Long currentUserId) {
        MatchRequest request = matchRequestRepository.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Yêu cầu không tồn tại!"));
        if (!request.getReceiver().getId().equals(currentUserId)) {
            throw new ForbiddenException("Không có quyền xử lý yêu cầu này!");
        }
        requireConnectable(request.getSender(), request.getReceiver());
        if (request.getStatus() != MatchRequest.MatchStatus.PENDING) {
            throw new IllegalArgumentException("Yêu cầu đã được xử lý");
        }

        request.setStatus(isAccepted ? MatchRequest.MatchStatus.ACCEPTED : MatchRequest.MatchStatus.REJECTED);
        matchRequestRepository.save(request);

        Map<String, Object> response = new HashMap<>();
        response.put("requestId", request.getId());
        response.put("status", request.getStatus().name());

        if (isAccepted) {
            response.put("message", "Kết nối thành công! Đã mở khóa thông tin liên hệ.");
            response.put("partnerName", request.getSender().getFullName());
            response.put("partnerPhone", request.getSender().getPhone());
            response.put("partnerEmail", request.getSender().getEmail());
        } else {
            response.put("message", "Đã từ chối yêu cầu kết nối.");
        }

        return response;
    }



    // Danh sách nhận được (mình là receiver)
    @Transactional(readOnly = true)
    public List<MatchRequestResponseDTO> getReceivedRequests(Long userId) {
        List<MatchRequest> list = matchRequestRepository.findByReceiverId(userId);
        return list.stream().filter(req -> canConnect(req.getSender(), req.getReceiver())).map(req -> {
            boolean isAccepted = req.getStatus() == MatchRequest.MatchStatus.ACCEPTED;
            return MatchRequestResponseDTO.builder()
                    .requestId(req.getId())
                    .partnerId(req.getSender().getId())
                    .partnerName(req.getSender().getFullName())
                    .partnerAvatar(req.getSender().getAvatarUrl())
                    .matchScore(req.getMatchScore())
                    .status(req.getStatus().name())
                    .createdAt(req.getCreatedAt())
                    .contactPhone(isAccepted ? req.getSender().getPhone() : null)
                    .contactEmail(isAccepted ? req.getSender().getEmail() : null)
                    .build();
        }).collect(Collectors.toList());
    }

    // Danh sách đã gửi (mình là sender)
    @Transactional(readOnly = true)
    public List<MatchRequestResponseDTO> getSentRequests(Long userId) {
        List<MatchRequest> list = matchRequestRepository.findBySenderId(userId);
        return list.stream().filter(req -> canConnect(req.getSender(), req.getReceiver())).map(req -> {
            boolean isAccepted = req.getStatus() == MatchRequest.MatchStatus.ACCEPTED;
            return MatchRequestResponseDTO.builder()
                    .requestId(req.getId())
                    .partnerId(req.getReceiver().getId())
                    .partnerName(req.getReceiver().getFullName())
                    .partnerAvatar(req.getReceiver().getAvatarUrl())
                    .matchScore(req.getMatchScore())
                    .status(req.getStatus().name())
                    .createdAt(req.getCreatedAt())
                    .contactPhone(isAccepted ? req.getReceiver().getPhone() : null)
                    .contactEmail(isAccepted ? req.getReceiver().getEmail() : null)
                    .build();
        }).collect(Collectors.toList());
    }

    @Transactional
    public void cancelConnection(Long currentUserId, Long partnerId) {
        matchRequestRepository.deleteAll(matchRequestRepository.findAllBetweenUsers(currentUserId, partnerId));
    }

    @Transactional
    public void cancelSentRequest(Long currentUserId, Long targetUserId) {
        matchRequestRepository.findBySenderIdAndReceiverId(currentUserId, targetUserId)
                .ifPresent(req -> {
                    if (req.getStatus() == com.roommate.hub.entity.MatchRequest.MatchStatus.PENDING) {
                        matchRequestRepository.delete(req);
                    }
                });
    }

    private boolean canConnect(User sender, User receiver) {
        return "ACTIVE".equalsIgnoreCase(sender.getStatus()) && "ACTIVE".equalsIgnoreCase(receiver.getStatus())
                && !blockedUserRepository.existsByUserIdAndBlockedUserId(sender.getId(), receiver.getId())
                && !blockedUserRepository.existsByUserIdAndBlockedUserId(receiver.getId(), sender.getId());
    }

    private void requireConnectable(User sender, User receiver) {
        if (!canConnect(sender, receiver)) throw new ForbiddenException("Không thể kết nối với người dùng này");
    }
}

