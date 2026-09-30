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
import org.springframework.beans.factory.ObjectProvider;
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
    private final ObjectProvider<R2StorageService> storageServiceProvider;

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

        String imageUrl = null;
        if (dto.getImageObjectKey() != null && !dto.getImageObjectKey().isBlank()) {
            R2StorageService storageService = storageServiceProvider.getIfAvailable();
            if (storageService == null) {
                throw new IllegalStateException("Cloudflare R2 chưa được cấu hình");
            }
            imageUrl = storageService.requireOwnedObject(
                    author.getId(), "room-post", dto.getImageObjectKey());
        }

        RoomPost post = RoomPost.builder()
                .author(author)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .price(dto.getPrice())
                .address(dto.getAddress())
                .district(dto.getDistrict())
                .deposit(dto.getDeposit())
                .electricityWaterCost(dto.getElectricityWaterCost())
                .area(dto.getArea())
                .maxOccupants(dto.getMaxOccupants())
                .currentOccupants(dto.getCurrentOccupants() == null ? 0 : dto.getCurrentOccupants())
                .amenities(dto.getAmenities())
                .imageUrl(imageUrl)
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
                .district(post.getDistrict())
                .deposit(post.getDeposit())
                .electricityWaterCost(post.getElectricityWaterCost())
                .area(post.getArea())
                .maxOccupants(post.getMaxOccupants())
                .currentOccupants(post.getCurrentOccupants())
                .amenities(post.getAmenities())
                .status(post.getStatus() != null ? post.getStatus().name() : null)
                .createdAt(post.getCreatedAt())
                .status(post.getStatus().name())
                .moderationReason(post.getModerationReason())
                .imageUrl(post.getImageUrl())
                .build();
    }

    @Transactional(readOnly = true)
    public RoomPostResponseDTO getPost(Long postId) {
        return convertToDTO(roomPostRepository.findByIdAndStatusIn(postId,
                List.of(RoomPost.PostStatus.APPROVED, RoomPost.PostStatus.AVAILABLE))
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
        // Đóng tin đăng (soft-close) để bảo toàn dữ liệu lịch hẹn và lịch sử tương tác
        post.setStatus(RoomPost.PostStatus.CLOSED);
        roomPostRepository.save(post);
    }

    @Transactional(readOnly = true)
    public List<RoomPostResponseDTO> getMyPosts() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User author = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Tài khoản người dùng không tồn tại!"));
        return roomPostRepository.findByAuthorId(author.getId())
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public RoomPostResponseDTO updatePost(Long postId, CreateRoomPostDTO dto) {
        RoomPost post = roomPostRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Bài đăng không tồn tại!"));
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean admin = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!admin && !post.getAuthor().getEmail().equals(authentication.getName())) {
            throw new ForbiddenException("Bạn không có quyền sửa bài đăng này!");
        }

        // Khi người dùng chỉnh sửa nội dung tin, chuyển về trạng thái PENDING để kiểm duyệt lại
        if (!admin) {
            post.setStatus(RoomPost.PostStatus.PENDING);
        }

        if (dto.getTitle() != null) post.setTitle(dto.getTitle());
        if (dto.getDescription() != null) post.setDescription(dto.getDescription());
        if (dto.getPrice() != null) post.setPrice(dto.getPrice());
        if (dto.getAddress() != null) post.setAddress(dto.getAddress());
        if (dto.getDistrict() != null) post.setDistrict(dto.getDistrict());
        if (dto.getDeposit() != null) post.setDeposit(dto.getDeposit());
        if (dto.getElectricityWaterCost() != null) post.setElectricityWaterCost(dto.getElectricityWaterCost());
        if (dto.getArea() != null) post.setArea(dto.getArea());
        if (dto.getMaxOccupants() != null) post.setMaxOccupants(dto.getMaxOccupants());
        if (dto.getCurrentOccupants() != null) post.setCurrentOccupants(dto.getCurrentOccupants());
        if (dto.getAmenities() != null) post.setAmenities(dto.getAmenities());

        if (dto.getImageObjectKey() != null && !dto.getImageObjectKey().isBlank()) {
            R2StorageService storageService = storageServiceProvider.getIfAvailable();
            if (storageService != null) {
                String imageUrl = storageService.requireOwnedObject(
                        post.getAuthor().getId(), "room-post", dto.getImageObjectKey());
                post.setImageUrl(imageUrl);
            }
        }

        return convertToDTO(roomPostRepository.save(post));
    }
}
