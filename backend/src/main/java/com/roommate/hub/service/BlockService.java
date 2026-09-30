package com.roommate.hub.service;

import com.roommate.hub.dto.BlockedUserDTO;
import com.roommate.hub.entity.BlockedUser;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BlockService {

    private final BlockedUserRepository blockedUserRepository;
    private final UserRepository userRepository;

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));
    }

    @Transactional
    public BlockedUserDTO blockUser(Long targetUserId) {
        User currentUser = getCurrentUser();
        if (currentUser.getId().equals(targetUserId)) {
            throw new IllegalArgumentException("Không thể tự chặn chính mình!");
        }
        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng cần chặn không tồn tại!"));

        if (blockedUserRepository.existsByUserIdAndBlockedUserId(currentUser.getId(), targetUserId)) {
            BlockedUser existing = blockedUserRepository.findByUserIdAndBlockedUserId(currentUser.getId(), targetUserId).orElseThrow();
            return toDTO(existing);
        }

        BlockedUser blockedUser = BlockedUser.builder()
                .user(currentUser)
                .blockedUser(targetUser)
                .build();
        return toDTO(blockedUserRepository.save(blockedUser));
    }

    @Transactional
    public void unblockUser(Long targetUserId) {
        User currentUser = getCurrentUser();
        blockedUserRepository.deleteByUserIdAndBlockedUserId(currentUser.getId(), targetUserId);
    }

    @Transactional(readOnly = true)
    public List<BlockedUserDTO> getMyBlockedUsers() {
        User currentUser = getCurrentUser();
        return blockedUserRepository.findByUserId(currentUser.getId())
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    private BlockedUserDTO toDTO(BlockedUser b) {
        return BlockedUserDTO.builder()
                .id(b.getId())
                .blockedUserId(b.getBlockedUser().getId())
                .blockedUserName(b.getBlockedUser().getFullName())
                .blockedUserAvatar(b.getBlockedUser().getAvatarUrl())
                .blockedUserEmail(b.getBlockedUser().getEmail())
                .createdAt(b.getCreatedAt())
                .build();
    }
}
