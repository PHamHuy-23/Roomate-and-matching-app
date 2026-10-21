package com.roommate.hub.service;

import com.roommate.hub.dto.AdminDashboardStatsDTO;
import com.roommate.hub.dto.AuditLogResponseDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.RoomPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReportExportService {

    private final AdminService adminService;
    private final RoomPostRepository roomPostRepository;
    private final MatchRequestRepository matchRequestRepository;

    private static final String CSV_BOM = "\uFEFF";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * Xuất toàn bộ nhật ký hệ thống
     * Cột: ID, Thời gian, Email Quản trị, Hành động, Đối tượng tác động, ID đối tượng, Chi tiết lý do
     */
    @Transactional(readOnly = true)
    public byte[] exportAuditLogsCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append(CSV_BOM);
        sb.append("ID,Thời gian,Email Quản trị,Hành động,Đối tượng tác động,ID đối tượng,Chi tiết lý do\n");

        List<AuditLogResponseDTO> logs = adminService.getAuditLogs();
        if (logs != null) {
            for (AuditLogResponseDTO log : logs) {
                String timeStr = log.getCreatedAt() != null
                        ? DATE_TIME_FORMATTER.format(log.getCreatedAt().atZone(ZoneId.systemDefault()))
                        : "";
                sb.append(escapeCsv(log.getId())).append(",")
                  .append(escapeCsv(timeStr)).append(",")
                  .append(escapeCsv(log.getActorEmail())).append(",")
                  .append(escapeCsv(log.getAction())).append(",")
                  .append(escapeCsv(log.getTargetType())).append(",")
                  .append(escapeCsv(log.getTargetId())).append(",")
                  .append(escapeCsv(log.getDetails()))
                  .append("\n");
            }
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Xuất danh sách người dùng
     * Cột: ID, Họ tên, Email, SĐT, Giới tính, Vai trò, Trạng thái, Ngày tạo
     */
    @Transactional(readOnly = true)
    public byte[] exportUsersCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append(CSV_BOM);
        sb.append("ID,Họ tên,Email,SĐT,Giới tính,Vai trò,Trạng thái,Ngày tạo\n");

        List<UserResponseDTO> users = adminService.getAllUsers();
        if (users != null) {
            for (UserResponseDTO u : users) {
                String createdStr = u.getCreatedAt() != null
                        ? DATE_TIME_FORMATTER.format(u.getCreatedAt())
                        : "";
                sb.append(escapeCsv(u.getId())).append(",")
                  .append(escapeCsv(u.getFullName())).append(",")
                  .append(escapeCsv(u.getEmail())).append(",")
                  .append(escapeCsv(u.getPhone())).append(",")
                  .append(escapeCsv(u.getGender())).append(",")
                  .append(escapeCsv(u.getRole())).append(",")
                  .append(escapeCsv(u.getStatus())).append(",")
                  .append(escapeCsv(createdStr))
                  .append("\n");
            }
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Xuất danh sách bài đăng phòng
     * Cột: ID, Tiêu đề, Quận, Giá phòng, Trạng thái, Số người ở tối đa, Tác giả, Ngày tạo
     */
    @Transactional(readOnly = true)
    public byte[] exportPostsCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append(CSV_BOM);
        sb.append("ID,Tiêu đề,Quận,Giá phòng,Trạng thái,Số người ở tối đa,Tác giả,Ngày tạo\n");

        List<RoomPost> posts = roomPostRepository.findAll();
        if (posts != null) {
            for (RoomPost p : posts) {
                String createdStr = p.getCreatedAt() != null
                        ? DATE_TIME_FORMATTER.format(p.getCreatedAt())
                        : "";
                String authorName = (p.getAuthor() != null) ? p.getAuthor().getFullName() : "";
                String statusStr = (p.getStatus() != null) ? p.getStatus().name() : "";
                String districtStr = p.getDistrict() != null ? p.getDistrict() : "";

                sb.append(escapeCsv(p.getId())).append(",")
                  .append(escapeCsv(p.getTitle())).append(",")
                  .append(escapeCsv(districtStr)).append(",")
                  .append(escapeCsv(p.getPrice())).append(",")
                  .append(escapeCsv(statusStr)).append(",")
                  .append(escapeCsv(p.getMaxOccupants())).append(",")
                  .append(escapeCsv(authorName)).append(",")
                  .append(escapeCsv(createdStr))
                  .append("\n");
            }
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Xuất báo cáo tổng quan chỉ số hệ thống
     * Cột: Chỉ số, Giá trị
     * Dữ liệu:
     * - Tổng người dùng
     * - Tỷ lệ ghép đôi thành công (%)
     * - Bài đăng chờ duyệt
     * - Báo cáo chờ xử lý
     * - Tổng số bài đăng
     * - Tổng số kết nối
     */
    @Transactional(readOnly = true)
    public byte[] exportSystemOverviewCsv() {
        StringBuilder sb = new StringBuilder();
        sb.append(CSV_BOM);
        sb.append("Chỉ số,Giá trị\n");

        AdminDashboardStatsDTO stats = adminService.getDashboardStats();
        long totalPosts = roomPostRepository.count();
        long totalConnections = matchRequestRepository.count();

        sb.append("Tổng người dùng,").append(stats.getTotalUsers()).append("\n");
        sb.append("Tỷ lệ ghép đôi thành công (%),").append(stats.getMatchSuccessRate()).append("%\n");
        sb.append("Bài đăng chờ duyệt,").append(stats.getPendingPosts()).append("\n");
        sb.append("Báo cáo chờ xử lý,").append(stats.getPendingReports()).append("\n");
        sb.append("Tổng số bài đăng,").append(totalPosts).append("\n");
        sb.append("Tổng số kết nối,").append(totalConnections).append("\n");

        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Chuẩn hoá và escape ký tự RFC 4180 cho CSV:
     * - Nếu giá trị chứa dấu phẩy (,), dấu ngoặc kép ("), ký tự xuống dòng (\n, \r),
     *   toàn bộ giá trị phải được bọc trong cặp ngoặc kép.
     * - Mọi dấu ngoặc kép (") bên trong phải được nhân đôi ("").
     */
    private String escapeCsv(Object val) {
        if (val == null) {
            return "";
        }
        String text = String.valueOf(val);
        boolean containsSpecialChar = text.contains(",") || text.contains("\"") || text.contains("\n") || text.contains("\r");
        if (containsSpecialChar) {
            text = text.replace("\"", "\"\"");
            return "\"" + text + "\"";
        }
        return text;
    }
}
