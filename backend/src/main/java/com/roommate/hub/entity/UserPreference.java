package com.roommate.hub.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_preferences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false, length = 100)
    private String targetDistrict;

    @Column(nullable = false)
    private Double budgetAmount; // VNĐ

    @Column(nullable = false)
    private Integer sleepHabit; // 1: Ngủ sớm, 2: Bình thường, 3: Cú đêm

    @Column(nullable = false)
    private Integer cleanlinessLevel; // Thang điểm 1 đến 5

    @Column(nullable = false)
    private Boolean isSmoking;

    @Column(nullable = false)
    private Boolean allowPets;

    @Column(columnDefinition = "TEXT")
    private String bioDescription;
}