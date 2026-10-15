package com.roommate.hub.repository;

import com.roommate.hub.entity.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long> {
    List<Report> findByReporterIdOrderByCreatedAtDesc(Long reporterId);
    List<Report> findByStatusOrderByCreatedAtDesc(String status);
}
