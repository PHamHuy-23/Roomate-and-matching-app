package com.roommate.hub.repository;

import com.roommate.hub.entity.ContactPermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ContactPermissionRepository extends JpaRepository<ContactPermission, Long> {

    boolean existsByUserIdAndGrantedToId(Long userId, Long grantedToId);

    Optional<ContactPermission> findByUserIdAndGrantedToId(Long userId, Long grantedToId);
}
