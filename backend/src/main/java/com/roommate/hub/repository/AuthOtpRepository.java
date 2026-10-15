package com.roommate.hub.repository;

import com.roommate.hub.entity.AuthOtp;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AuthOtpRepository extends JpaRepository<AuthOtp, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<AuthOtp> findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(
            String email,
            AuthOtp.OtpType type
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM AuthOtp o WHERE o.id = :id")
    Optional<AuthOtp> findByIdForUpdate(@Param("id") Long id);

    Optional<AuthOtp> findTopByEmailAndTypeOrderByCreatedAtDesc(
            String email,
            AuthOtp.OtpType type
    );

    long countByEmailAndTypeAndCreatedAtAfter(
            String email,
            AuthOtp.OtpType type,
            java.time.LocalDateTime after
    );

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE AuthOtp o SET o.used = true WHERE o.email = :email AND o.type = :type AND o.used = false")
    int invalidateAllActiveByEmailAndType(@Param("email") String email, @Param("type") AuthOtp.OtpType type);

    @Query(value = "SELECT pg_advisory_xact_lock(hashtext(:key))", nativeQuery = true)
    Object acquirePgAdvisoryLock(@Param("key") String key);
}
