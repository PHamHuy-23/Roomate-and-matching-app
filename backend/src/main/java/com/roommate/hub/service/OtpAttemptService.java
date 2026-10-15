package com.roommate.hub.service;

import com.roommate.hub.entity.AuthOtp;
import com.roommate.hub.repository.AuthOtpRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OtpAttemptService {

    private final AuthOtpRepository authOtpRepository;

    @Transactional
    public int recordFailedAttempt(AuthOtp otp) {
        otp.incrementFailedAttempts();
        authOtpRepository.saveAndFlush(otp);
        return otp.getFailedAttempts();
    }

    @Transactional
    public void markUsed(AuthOtp otp) {
        otp.setUsed(true);
        authOtpRepository.saveAndFlush(otp);
    }
}
