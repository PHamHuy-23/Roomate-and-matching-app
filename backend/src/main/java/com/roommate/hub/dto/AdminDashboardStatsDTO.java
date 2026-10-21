package com.roommate.hub.dto;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class AdminDashboardStatsDTO {
    long totalUsers;
    double matchSuccessRate;
    long pendingPosts;
    long pendingReports;
}
