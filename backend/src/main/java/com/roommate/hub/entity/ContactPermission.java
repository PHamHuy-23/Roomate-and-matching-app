package com.roommate.hub.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "contact_permissions", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "granted_to_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ContactPermission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "granted_to_id", nullable = false)
    private User grantedTo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "match_request_id", nullable = false)
    private MatchRequest matchRequest;

    @CreationTimestamp
    @Column(name = "granted_at", nullable = false, updatable = false)
    private LocalDateTime grantedAt;
}
