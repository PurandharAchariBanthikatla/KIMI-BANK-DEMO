package com.kimibank.auth;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OtpVerificationRepository extends JpaRepository<OtpVerification, UUID> {
    Optional<OtpVerification> findTopByPhoneNumberAndPurposeAndConsumedFalseOrderByCreatedAtDesc(
            String phoneNumber, String purpose);
}
