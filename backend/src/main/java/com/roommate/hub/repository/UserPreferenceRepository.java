package com.roommate.hub.repository;

import com.roommate.hub.entity.UserPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface UserPreferenceRepository extends JpaRepository<UserPreference, Long> {
    Optional<UserPreference> findByUserId(Long userId);

    @Query("SELECT p FROM UserPreference p JOIN p.user u " +
            "WHERE u.id != :currentUserId AND u.gender = :gender AND p.targetDistrict = :district")
    List<UserPreference> findCandidates(
            @Param("currentUserId") Long currentUserId,
            @Param("gender") String gender,
            @Param("district") String district
    );
}