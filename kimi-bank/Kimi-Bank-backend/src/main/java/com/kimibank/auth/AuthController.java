package com.kimibank.auth;

import com.kimibank.auth.dto.AuthDtos.*;
import jakarta.validation.Valid;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final OtpService otpService;

    public AuthController(AuthService authService, OtpService otpService) {
        this.authService = authService;
        this.otpService = otpService;
    }

    @PostMapping("/otp/request")
    public OtpDevResponse requestOtp(@Valid @RequestBody OtpRequest request) {
        String otp = authService.requestOtp(request.phoneNumber(), request.purpose());
        // devOtp is only ever populated in dev-mode (see application.yml); never in production.
        return otpService.isDevMode()
                ? new OtpDevResponse("OTP sent", otp)
                : new OtpDevResponse("OTP sent", null);
    }

    @PostMapping("/signup")
    public TokenResponse signup(@RequestParam String otp, @Valid @RequestBody SignupRequest request) {
        return authService.completeSignup(request, otp);
    }

    @PostMapping("/mpin/set")
    public void setMpin(@Valid @RequestBody SetMpinRequest request) {
        UUID userId = currentUserId();
        authService.setMpin(userId, request.mpin());
    }

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginMpinRequest request) {
        return authService.loginWithMpin(request.phoneNumber(), request.mpin());
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken());
    }

    private UUID currentUserId() {
        return (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
