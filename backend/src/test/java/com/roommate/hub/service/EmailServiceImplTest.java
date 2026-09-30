package com.roommate.hub.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmailServiceImplTest {

    @Mock
    private JavaMailSender mailSender;

    @Test
    @DisplayName("EmailServiceImpl ném SERVICE_UNAVAILABLE khi JavaMailSender chưa được cấu hình")
    void sendOtp_WhenMailSenderMissing_ShouldThrowServiceUnavailable() {
        EmailServiceImpl serviceWithoutSender = new EmailServiceImpl(null);

        assertThatThrownBy(() -> serviceWithoutSender.sendPasswordResetOtp("test@example.com", "123456"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    @Test
    @DisplayName("EmailServiceImpl ném SERVICE_UNAVAILABLE khi SMTP thất bại để transaction rollback (OTP không được lưu vào DB)")
    void sendOtp_WhenMailSendingFails_ShouldThrowServiceUnavailable() {
        doThrow(new MailSendException("SMTP connection error")).when(mailSender).send(any(SimpleMailMessage.class));
        EmailServiceImpl service = new EmailServiceImpl(mailSender);

        assertThatThrownBy(() -> service.sendPasswordResetOtp("test@example.com", "123456"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    @Test
    @DisplayName("EmailServiceImpl gửi email thành công khi cấu hình hợp lệ")
    void sendOtp_WhenSuccess_ShouldCallMailSender() {
        EmailServiceImpl service = new EmailServiceImpl(mailSender);

        service.sendPasswordResetOtp("test@example.com", "123456");

        verify(mailSender, times(1)).send(any(SimpleMailMessage.class));
    }

    @Test
    @DisplayName("simulateDeliveryDelay() ném SERVICE_UNAVAILABLE khi JavaMailSender chưa cấu hình")
    void simulateDeliveryDelay_WhenMailSenderMissing_ShouldThrowServiceUnavailable() {
        EmailServiceImpl serviceWithoutSender = new EmailServiceImpl(null);

        assertThatThrownBy(serviceWithoutSender::simulateDeliveryDelay)
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }
}
