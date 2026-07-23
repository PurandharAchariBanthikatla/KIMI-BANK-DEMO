package com.kimibank.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class AuthDtos {

    public record SignupRequest(
            @NotBlank String fullName,
            @NotBlank @Pattern(regexp = "\\d{10}") String phoneNumber
    ) {}

    public record OtpRequest(
            @NotBlank @Pattern(regexp = "\\d{10}") String phoneNumber,
            @NotBlank String purpose // SIGNUP, LOGIN, RESET_MPIN
    ) {}

    public record OtpVerifyRequest(
            @NotBlank @Pattern(regexp = "\\d{10}") String phoneNumber,
            @NotBlank String purpose,
            @NotBlank String otp
    ) {}

    public record SetMpinRequest(
            @NotBlank @Pattern(regexp = "\\d{4,6}") String mpin
    ) {}

    public record LoginMpinRequest(
            @NotBlank @Pattern(regexp = "\\d{10}") String phoneNumber,
            @NotBlank String mpin
    ) {}

    public record RefreshRequest(@NotBlank String refreshToken) {}

    public record TokenResponse(String accessToken, String refreshToken, String userId) {}

    public record OtpDevResponse(String message, String devOtp) {}
}
