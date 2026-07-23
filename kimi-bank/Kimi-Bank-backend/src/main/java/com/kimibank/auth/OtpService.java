package com.kimibank.auth;

import com.kimibank.common.ApiException;
import com.kimibank.config.OtpProperties;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Optional;

@Service
public class OtpService {

    private final OtpVerificationRepository otpRepository;
    private final OtpProperties otpProperties;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    public OtpService(OtpVerificationRepository otpRepository, OtpProperties otpProperties,
                       PasswordEncoder passwordEncoder) {
        this.otpRepository = otpRepository;
        this.otpProperties = otpProperties;
        this.passwordEncoder = passwordEncoder;
    }

    /** Generates and stores an OTP. Returns the plaintext OTP ONLY for dev-mode logging/response. */
    public String issueOtp(String phoneNumber, String purpose) {
        String otp = generateNumericOtp(otpProperties.getLength());

        OtpVerification entity = new OtpVerification();
        entity.setPhoneNumber(phoneNumber);
        entity.setPurpose(purpose);
        entity.setOtpHash(passwordEncoder.encode(otp));
        entity.setMaxAttempts(otpProperties.getMaxAttempts());
        entity.setExpiresAt(Instant.now().plusSeconds(otpProperties.getTtlSeconds()));
        otpRepository.save(entity);

        // In production: send via SMS gateway (e.g. MSG91 / Twilio) instead of returning it.
        return otp;
    }

    public void verifyOtp(String phoneNumber, String purpose, String candidate) {
        Optional<OtpVerification> maybeOtp = otpRepository
                .findTopByPhoneNumberAndPurposeAndConsumedFalseOrderByCreatedAtDesc(phoneNumber, purpose);

        OtpVerification otp = maybeOtp.orElseThrow(() ->
                new ApiException(HttpStatus.BAD_REQUEST, "No active OTP request found"));

        if (otp.isConsumed() || otp.getExpiresAt().isBefore(Instant.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "OTP has expired. Please request a new one");
        }
        if (otp.getAttempts() >= otp.getMaxAttempts()) {
            throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "Maximum OTP attempts exceeded");
        }

        otp.setAttempts(otp.getAttempts() + 1);

        if (!passwordEncoder.matches(candidate, otp.getOtpHash())) {
            otpRepository.save(otp);
            throw new ApiException(HttpStatus.BAD_REQUEST, "Incorrect OTP");
        }

        otp.setConsumed(true);
        otpRepository.save(otp);
    }

    private String generateNumericOtp(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(secureRandom.nextInt(10));
        }
        return sb.toString();
    }

    public boolean isDevMode() {
        return otpProperties.isDevMode();
    }
}
