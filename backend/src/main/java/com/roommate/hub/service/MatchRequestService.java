package com.roommate.hub.service;

import com.roommate.hub.dto.MatchRequestResponseDTO;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MatchRequestService {

    private final MatchRequestRepository matchRequestRepository;
    private final UserRepository userRepository;

    public MatchRequest sendRequest(Long senderId, Long receiverId, Double score) {
        if (senderId.equals(receiverId)) {
            throw new RuntimeException("Không thể tự ghép đôi với chính mình!");
        }

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found"));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found"));

        return matchRequestRepository.findBySenderIdAndReceiverId(senderId, receiverId)
                .orElseGet(() -> matchRequestRepository.save(MatchRequest.builder()
                        .sender(sender)
                        .receiver(receiver)
                        .matchScore(score)
                        .status(MatchRequest.MatchStatus.PENDING)
                        .build()));
    }

    @Transactional
    public Map<String, Object> respondRequest(Long requestId, boolean isAccepted) {
        MatchRequest request = matchRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Yêu cầu không tồn tại!"));

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
        return list.stream().map(req -> {
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

    // Danh sách đã gửi đi (mình là sender)
    @Transactional(readOnly = true)
    public List<MatchRequestResponseDTO> getSentRequests(Long userId) {
        List<MatchRequest> list = matchRequestRepository.findBySenderId(userId);
        return list.stream().map(req -> {
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
}