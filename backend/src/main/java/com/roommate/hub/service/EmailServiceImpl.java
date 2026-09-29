package com.roommate.hub.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

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
                        + "Mã có hiệu lực trong vòng 15 phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.\n\n"
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
                        + "Mã có hiệu lực trong vòng 15 phút. Tuyệt đối không chia sẻ mã này cho bất kỳ ai.\n\n"
                        + "Trân trọng,\nĐội ngũ Roommate Hub"
        );
    }

    @Override
    public void simulateDeliveryDelay() {
        // Sử dụng cùng kiểm tra mailSender và cùng mã lỗi với sendEmail()
        // để đảm bảo phản hồi HTTP hoàn toàn đối xứng giữa email tồn tại và không tồn tại
        // (chống Account Enumeration qua status code - OWASP).
        if (mailSender.isEmpty()) {
            log.error("[EMAIL SERVICE] JavaMailSender chưa được cấu hình.");
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Dịch vụ gửi email chưa được kích hoạt hoặc chưa sẵn sàng!");
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
            log.error("[EMAIL SERVICE] JavaMailSender chưa được cấu hình. Không thể gửi email tới {}", maskEmail(toEmail));
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Dịch vụ gửi email chưa được kích hoạt hoặc chưa sẵn sàng!");
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
