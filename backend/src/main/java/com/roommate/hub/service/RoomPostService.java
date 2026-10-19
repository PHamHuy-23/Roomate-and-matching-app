package com.roommate.hub.service;

import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.util.DistrictNames;
import com.roommate.hub.dto.RoomPostResponseDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomPostService {

    private final RoomPostRepository roomPostRepository;
    private final UserRepository userRepository;
    private final ObjectProvider<R2StorageService> storageServiceProvider;

    @Transactional(readOnly = true)
    public List<RoomPostResponseDTO> getAllAvailablePosts() {
        return roomPostRepository.findByStatusInAndAuthorStatus(
                List.of(RoomPost.PostStatus.APPROVED, RoomPost.PostStatus.AVAILABLE), "ACTIVE")
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public RoomPostResponseDTO createPost(CreateRoomPostDTO dto) {
        validateFiniteNumbers(dto);
        validateOccupancy(dto.getMaxOccupants(), dto.getCurrentOccupants() == null ? 0 : dto.getCurrentOccupants());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User author = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Tài khoản người dùng không tồn tại!"));

        // Resolve multiple or single image keys with strict ownership check (max 4 images)
        String imageUrl = resolveImages(author.getId(), dto, null);

        RoomPost post = RoomPost.builder()
                .author(author)
                .title(dto.getTitle())
                .description(dto.getDescription())
                .price(dto.getPrice())
                .address(dto.getAddress())
                .district(DistrictNames.canonical(dto.getDistrict()))
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
                .district(DistrictNames.canonical(post.getDistrict()))
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
        return convertToDTO(roomPostRepository.findByIdAndStatusInAndAuthorStatus(postId,
                List.of(RoomPost.PostStatus.APPROVED, RoomPost.PostStatus.AVAILABLE), "ACTIVE")
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

        validateFiniteNumbers(dto);
        validateOccupancy(dto.getMaxOccupants() == null ? post.getMaxOccupants() : dto.getMaxOccupants(),
                dto.getCurrentOccupants() == null ? post.getCurrentOccupants() : dto.getCurrentOccupants());

        // Resolve requested replacement / multi-image album (max 4 images)
        String newImageUrl = resolveImages(post.getAuthor().getId(), dto, post.getImageUrl());
        boolean hasImageChange = (dto.getImageObjectKeys() != null)
                || (dto.getImageUrls() != null)
                || (dto.getImageObjectKey() != null);

        // Khi người dùng chỉnh sửa nội dung tin, chuyển về trạng thái PENDING để kiểm duyệt lại
        if (!admin) {
            post.setStatus(RoomPost.PostStatus.PENDING);
        }

        if (dto.getTitle() != null) post.setTitle(dto.getTitle());
        if (dto.getDescription() != null) post.setDescription(dto.getDescription());
        if (dto.getPrice() != null) post.setPrice(dto.getPrice());
        if (dto.getAddress() != null) post.setAddress(dto.getAddress());
        if (dto.getDistrict() != null) post.setDistrict(DistrictNames.canonical(dto.getDistrict()));
        if (dto.getDeposit() != null) post.setDeposit(dto.getDeposit());
        if (dto.getElectricityWaterCost() != null) post.setElectricityWaterCost(dto.getElectricityWaterCost());
        if (dto.getArea() != null) post.setArea(dto.getArea());
        if (dto.getMaxOccupants() != null) post.setMaxOccupants(dto.getMaxOccupants());
        if (dto.getCurrentOccupants() != null) post.setCurrentOccupants(dto.getCurrentOccupants());
        if (dto.getAmenities() != null) post.setAmenities(dto.getAmenities());

        if (hasImageChange) {
            post.setImageUrl(newImageUrl);
        }

        return convertToDTO(roomPostRepository.save(post));
    }

    private String resolveImages(Long authorId, CreateRoomPostDTO dto, String existingImageUrl) {
        java.util.List<String> combinedUrls = new java.util.ArrayList<>();

        // 1. Giữ lại các ảnh URL hợp lệ đã tồn tại (cho phép xóa bớt 1 trong các ảnh cũ)
        if (dto.getImageUrls() != null) {
            for (String url : dto.getImageUrls()) {
                if (url != null && !url.isBlank()) {
                    String cleanUrl = url.trim();
                    if (!combinedUrls.contains(cleanUrl)) {
                        combinedUrls.add(cleanUrl);
                    }
                }
            }
        }

        // 2. Kiểm tra và bổ sung các ảnh mới upload lên qua R2 Object Keys
        if (dto.getImageObjectKeys() != null) {
            for (String key : dto.getImageObjectKeys()) {
                if (key != null && !key.isBlank()) {
                    String resolvedUrl = requireImageUrl(authorId, key.trim());
                    if (!combinedUrls.contains(resolvedUrl)) {
                        combinedUrls.add(resolvedUrl);
                    }
                }
            }
        }

        // 3. Fallback cho single imageObjectKey (tương thích ngược)
        if (dto.getImageObjectKey() != null && !dto.getImageObjectKey().isBlank()) {
            String resolvedUrl = requireImageUrl(authorId, dto.getImageObjectKey().trim());
            if (!combinedUrls.contains(resolvedUrl)) {
                combinedUrls.add(resolvedUrl);
            }
        }

        // 4. Ràng buộc bảo mật & dung lượng: Tối đa 4 ảnh
        if (combinedUrls.size() > 4) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Một bài đăng chỉ được tối đa 4 hình ảnh");
        }

        if (combinedUrls.isEmpty()) {
            return null;
        }
        return String.join(",", combinedUrls);
    }

    private String requireImageUrl(Long authorId, String imageObjectKey) {
        R2StorageService storageService = storageServiceProvider.getIfAvailable();
        if (storageService == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Cloudflare R2 chưa được cấu hình");
        }
        return storageService.requireOwnedObject(authorId, "room-post", imageObjectKey);
    }

    private void validateFiniteNumbers(CreateRoomPostDTO dto) {
        for (Double value : new Double[]{dto.getPrice(), dto.getDeposit(), dto.getElectricityWaterCost(), dto.getArea()}) {
            if (value != null && !Double.isFinite(value)) {
                throw new IllegalArgumentException("Giá, tiền cọc, chi phí điện nước và diện tích phải là số hữu hạn");
            }
        }
    }

    private void validateOccupancy(Integer maxOccupants, Integer currentOccupants) {
        if (maxOccupants == null || maxOccupants < 1) {
            throw new IllegalArgumentException("Số người tối đa phải lớn hơn hoặc bằng 1");
        }
        if (currentOccupants == null || currentOccupants < 0 || currentOccupants > maxOccupants) {
            throw new IllegalArgumentException("Số người hiện tại phải từ 0 đến số người tối đa");
        }
    }
}
