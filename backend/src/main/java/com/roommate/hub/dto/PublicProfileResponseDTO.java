package com.roommate.hub.dto;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class PublicProfileResponseDTO {
    Long userId;
    String fullName;
    String avatarUrl;
    String university;
    String targetDistrict;
    Double budgetMin;
    Double budgetMax;
    Integer sleepHabit;
    Integer cleanlinessLevel;
    Boolean isSmoking;
    Boolean allowPets;
    String bioDescription;
}
