package com.roommate.hub.service;

import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.dto.RoomPostResponseDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomPostService {

    private final RoomPostRepository roomPostRepository;
    private final UserRepository userRepository;

    public List<RoomPostResponseDTO> getAllAvailablePosts() {
        return roomPostRepository.findByStatusIn(List.of(RoomPost.PostStatus.APPROVED, RoomPost.PostStatus.AVAILABLE))
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public RoomPostResponseDTO createPost(CreateRoomPostDTO dto) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User author = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Tài khoản người dùng không tồn tại!"));

        RoomPost post = RoomPost.builder()
                .author(author)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .price(dto.getPrice())
                .address(dto.getAddress())
                .maxOccupants(dto.getMaxOccupants())
                .imageUrl(dto.getImageUrl())
                .status(RoomPost.PostStatus.PENDING) // Mặc định chờ duyệt
                .build();

        return convertToDTO(roomPostRepository.save(post));
    }

    private RoomPostResponseDTO convertToDTO(RoomPost post) {
        return RoomPostResponseDTO.builder()
                .id(post.getId())
                .authorId(post.getAuthor().getId())
                .authorName(post.getAuthor().getFullName())
                .authorAvatar(post.getAuthor().getAvatarUrl())
                .title(post.getTitle())
                .description(post.getDescription())
                .price(post.getPrice())
                .address(post.getAddress())
                .maxOccupants(post.getMaxOccupants())
                .createdAt(post.getCreatedAt())
                .imageUrl(post.getImageUrl())
                .build();
    }

    @Transactional(readOnly = true)
    public RoomPostResponseDTO getPost(Long postId) {
        return convertToDTO(roomPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng không tồn tại!")));
    }

    @Transactional
    public void deletePost(Long postId) {
        RoomPost post = roomPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng không tồn tại!"));
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean admin = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!admin && !post.getAuthor().getEmail().equals(authentication.getName())) {
            throw new ForbiddenException("Bạn không có quyền xóa bài đăng này!");
        }
        roomPostRepository.delete(post);
    }
}
