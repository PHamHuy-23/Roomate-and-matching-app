package com.roommate.hub.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "room_posts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private User author;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String description;

    @Column(nullable = false)
    private Double price;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(length = 100)
    private String district;

    private Double deposit;

    @Column(name = "electricity_water_cost")
    private Double electricityWaterCost;

    private Double area;

    @Column(nullable = false)
    private Integer maxOccupants;

    @Column(nullable = false)
    @Builder.Default
    private Integer currentOccupants = 0;

    @Column(length = 500)
    private String amenities;

    @Column(length = 255)
    private String imageUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PostStatus status; // AVAILABLE, FILLED

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    public enum PostStatus {
        PENDING,    // Chờ Admin duyệt
        APPROVED,   // Đã duyệt (hiển thị công khai)
        REJECTED,   // Bị từ chối
        AVAILABLE   // Tương đương APPROVED
    }
}