package com.roommate.hub.service;

import com.roommate.hub.dto.CreateRoomPostDTO;
import com.roommate.hub.dto.RoomPostResponseDTO;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
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
        User author = userRepository.findById(dto.getAuthorId())
                .orElseThrow(() -> new RuntimeException("Tài khoản người dùng không tồn tại!"));

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
                .currentOccupants(dto.getCurrentOccupants() != null ? dto.getCurrentOccupants() : 0)
                .amenities(dto.getAmenities())
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
                .createdAt(post.getCreatedAt())
                .build();
    }
}