package com.roommate.hub.repository;

import com.roommate.hub.entity.ContactPermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ContactPermissionRepository extends JpaRepository<ContactPermission, Long> {

    boolean existsByUserIdAndGrantedToId(Long userId, Long grantedToId);

    Optional<ContactPermission> findByUserIdAndGrantedToId(Long userId, Long grantedToId);

    @Modifying
    @Query("DELETE FROM ContactPermission cp WHERE (cp.user.id = :u1 AND cp.grantedTo.id = :u2) OR (cp.user.id = :u2 AND cp.grantedTo.id = :u1)")
    void deleteBetweenUsers(@Param("u1") Long u1, @Param("u2") Long u2);
}
