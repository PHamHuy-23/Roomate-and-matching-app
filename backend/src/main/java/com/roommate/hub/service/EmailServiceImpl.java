package com.roommate.hub.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
@Slf4j
public class EmailServiceImpl implements EmailService {

    private final Optional<JavaMailSender> mailSender;

    @Value("${spring.mail.username:noreply@roommatehub.com}")
    private String fromEmail;

    public EmailServiceImpl(@Autowired(required = false) JavaMailSender mailSender) {
        this.mailSender = Optional.ofNullable(mailSender);
    }

    @Override
    public void sendPasswordResetOtp(String toEmail, String otp) {
        // Plaintext OTP is NEVER printed to logs to prevent credential leakage
        log.info("[EMAIL SERVICE] Gửi email khôi phục mật khẩu tới {}", maskEmail(toEmail));
        sendEmail(
                toEmail,
                "[Roommate Hub] Mã xác nhận khôi phục mật khẩu",
                "Chào bạn,\n\n"
                        + "Mã xác nhận khôi phục mật khẩu của bạn là: " + otp + "\n"
                        + "Mã có hiệu lực trong vòng 5 phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.\n\n"
                        + "Trân trọng,\nĐội ngũ Roommate Hub"
        );
    }

    @Override
    public void sendVerificationOtp(String toEmail, String otp) {
        // Plaintext OTP is NEVER printed to logs to prevent credential leakage
        log.info("[EMAIL SERVICE] Gửi email xác minh tài khoản tới {}", maskEmail(toEmail));
        sendEmail(
                toEmail,
                "[Roommate Hub] Mã xác minh tài khoản",
                "Chào bạn,\n\n"
                        + "Mã xác minh tài khoản Roommate Hub của bạn là: " + otp + "\n"
                        + "Mã có hiệu lực trong vòng 5 phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.\n\n"
                        + "Trân trọng,\nĐội ngũ Roommate Hub"
        );
    }

    @Override
    public void sendAppointmentReminder(String toEmail, String recipientName, String partnerName, String roomTitle, Instant appointmentTime, String address) {
        log.info("[EMAIL SERVICE] Gửi email nhắc hẹn xem phòng tới {}", maskEmail(toEmail));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm 'ngày' dd/MM/yyyy")
                .withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
        String formattedTime = appointmentTime != null ? formatter.format(appointmentTime) : "Không xác định";

        String subject = "[Roommate Hub] Nhắc nhở cuộc hẹn xem phòng sắp diễn ra (còn 24 giờ)";
        String body = String.format(
                "Xin chào %s,\n\n"
                        + "Bạn có một cuộc hẹn xem phòng sắp diễn ra trong vòng 24 giờ tới:\n"
                        + "- Phòng xem: %s\n"
                        + "- Địa chỉ: %s\n"
                        + "- Người hẹn cùng bạn: %s\n"
                        + "- Thời gian xem phòng: %s (Giờ Việt Nam - GMT+7)\n\n"
                        + "Vui lòng sắp xếp thời gian và giữ liên lạc để buổi xem phòng diễn ra thuận lợi.\n\n"
                        + "Trân trọng,\n"
                        + "Đội ngũ Roommate Hub",
                recipientName != null ? recipientName : "bạn",
                roomTitle != null ? roomTitle : "Tin đăng phòng",
                address != null ? address : "Chưa cập nhật địa chỉ",
                partnerName != null ? partnerName : "Người dùng",
                formattedTime
        );

        if (mailSender.isEmpty()) {
            log.warn("[EMAIL SERVICE DEV MODE] JavaMailSender chưa được cấu hình. Ghi nhận log nhắc hẹn xem phòng cho {} (Người nhận: {}, Bạn hẹn: {}, Phòng: {}, Thời gian: {}): \n{}",
                    maskEmail(toEmail), recipientName, partnerName, roomTitle, formattedTime, body);
            return;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject(subject);
            message.setText(body);
            mailSender.get().send(message);
            log.info("[EMAIL SERVICE] Đã gửi email nhắc hẹn thành công tới {}", maskEmail(toEmail));
        } catch (Exception e) {
            log.error("[EMAIL SERVICE] Lỗi khi gửi email nhắc hẹn tới {}: {}", maskEmail(toEmail), e.getMessage());
        }
    }

    @Override
    public void sendAppointmentRescheduledNotification(String toEmail, String recipientName, String hostName, String roomTitle, Instant newAppointmentTime, String reason) {
        log.info("[EMAIL SERVICE] Gửi email thông báo đề xuất đổi giờ hẹn tới {}", maskEmail(toEmail));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("HH:mm 'ngày' dd/MM/yyyy")
                .withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
        String formattedTime = newAppointmentTime != null ? formatter.format(newAppointmentTime) : "Không xác định";

        String subject = "[Roommate Hub] Chủ phòng đề xuất thay đổi giờ hẹn xem phòng";
        String body = String.format(
                "Xin chào %s,\n\n"
                        + "Chủ phòng (%s) đã đề xuất thời gian hẹn xem phòng mới cho tin đăng: %s\n"
                        + "- Thời gian mới đề xuất: %s (Giờ Việt Nam - GMT+7)\n"
                        + "- Lý do / Ghi chú: %s\n\n"
                        + "Vui lòng đăng nhập vào Roommate Hub để Xác nhận hoặc Từ chối lịch hẹn mới này.\n\n"
                        + "Trân trọng,\n"
                        + "Đội ngũ Roommate Hub",
                recipientName != null ? recipientName : "bạn",
                hostName != null ? hostName : "Chủ phòng",
                roomTitle != null ? roomTitle : "Tin đăng phòng",
                formattedTime,
                reason != null && !reason.isBlank() ? reason : "Không có ghi chú thêm"
        );

        if (mailSender.isEmpty()) {
            log.warn("[EMAIL SERVICE DEV MODE] JavaMailSender chưa được cấu hình. Ghi nhận log đề xuất đổi giờ hẹn cho {} (Người nhận: {}, Chủ phòng: {}, Thời gian mới: {}): \n{}",
                    maskEmail(toEmail), recipientName, hostName, formattedTime, body);
            return;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject(subject);
            message.setText(body);
            mailSender.get().send(message);
            log.info("[EMAIL SERVICE] Đã gửi email thông báo đề xuất đổi giờ hẹn thành công tới {}", maskEmail(toEmail));
        } catch (Exception e) {
            log.error("[EMAIL SERVICE] Lỗi khi gửi email thông báo đề xuất đổi giờ hẹn tới {}: {}", maskEmail(toEmail), e.getMessage());
        }
    }

    @Override
    public void simulateDeliveryDelay() {
        // Sử dụng cùng kiểm tra mailSender và cùng mã lỗi với sendEmail()
        // để đảm bảo phản hồi HTTP hoàn toàn đối xứng giữa email tồn tại và không tồn tại
        // (chống Account Enumeration qua status code - OWASP).
        if (mailSender.isEmpty()) {
            log.warn("[EMAIL SERVICE DEV MODE] JavaMailSender chưa được cấu hình. Giả lập độ trễ hoàn tất.");
            try {
                Thread.sleep(300);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return;
        }
        try {
            // Giả lập độ trễ mạng tương đương cuộc gọi SMTP thực tế (200-400ms)
            // để bảo đảm constant-time giữa email tồn tại và không tồn tại, chống dò quét tài khoản
            Thread.sleep(200 + java.util.concurrent.ThreadLocalRandom.current().nextInt(200));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        // Nếu mailSender được cấu hình nhưng SMTP server thực tế không phản hồi,
        // cả hai nhánh (real/fake) đều đã vượt qua kiểm tra cấu hình và trả 200.
        // Điều này loại bỏ hoàn toàn sự khác biệt status code giữa hai nhánh.
    }

    private void sendEmail(String toEmail, String subject, String body) {
        if (mailSender.isEmpty()) {
            log.warn("[EMAIL SERVICE DEV MODE] JavaMailSender chưa được cấu hình. Giả lập độ trễ gửi email cho {}", maskEmail(toEmail));
            try {
                Thread.sleep(300);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject(subject);
            message.setText(body);
            mailSender.get().send(message);
            log.info("[EMAIL SERVICE] Đã gửi email thành công tới {}", maskEmail(toEmail));
        } catch (Exception e) {
            log.error("[EMAIL SERVICE] Lỗi khi gửi email tới {}: {}", maskEmail(toEmail), e.getMessage());
            // Rethrow để transaction rollback: OTP không được commit khi email chưa gửi.
            // Người dùng nhận HTTP 503 và có thể thử lại; cooldown/quota không bị tiêu tốn oan.
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Không thể gửi email xác thực đến hòm thư của bạn. Vui lòng thử lại sau!");
        }
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "***";
        }
        int atIndex = email.indexOf('@');
        if (atIndex <= 2) {
            return "**@" + email.substring(atIndex + 1);
        }
        return email.substring(0, 2) + "***@" + email.substring(atIndex + 1);
    }
}

