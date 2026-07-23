package com.kimibank.auth;

import com.kimibank.account.AccountService;
import com.kimibank.auth.dto.AuthDtos.*;
import com.kimibank.common.ApiException;
import com.kimibank.security.JwtService;
import com.kimibank.wallet.WalletService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AccountService accountService;
    private final WalletService walletService;

    public AuthService(UserRepository userRepository, OtpService otpService, PasswordEncoder passwordEncoder,
                        JwtService jwtService, AccountService accountService, WalletService walletService) {
        this.userRepository = userRepository;
        this.otpService = otpService;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.accountService = accountService;
        this.walletService = walletService;
    }

    public String requestOtp(String phoneNumber, String purpose) {
        if ("SIGNUP".equals(purpose) && userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new ApiException(HttpStatus.CONFLICT, "Phone number already registered");
        }
        if ("LOGIN".equals(purpose) && !userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "No account found for this phone number");
        }
        return otpService.issueOtp(phoneNumber, purpose);
    }

    @Transactional
    public TokenResponse completeSignup(SignupRequest request, String otp) {
        otpService.verifyOtp(request.phoneNumber(), "SIGNUP", otp);

        User user = new User();
        user.setFullName(request.fullName());
        user.setPhoneNumber(request.phoneNumber());
        user = userRepository.save(user);

        // Provision default account + wallet for the new user (MVP: instant, no core-banking partner yet).
        accountService.createDefaultAccount(user.getId());
        walletService.createWallet(user.getId());

        return issueTokenPair(user);
    }

    @Transactional
    public void setMpin(UUID userId, String mpin) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        user.setMpinHash(passwordEncoder.encode(mpin));
        userRepository.save(user);
    }

    public TokenResponse loginWithMpin(String phoneNumber, String mpin) {
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

        if (user.getMpinHash() == null || !passwordEncoder.matches(mpin, user.getMpinHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }
        if (!"ACTIVE".equals(user.getStatus())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Account is not active");
        }
        return issueTokenPair(user);
    }

    public TokenResponse refresh(String refreshToken) {
        if (!jwtService.isValid(refreshToken)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid or expired refresh token");
        }
        UUID userId = jwtService.extractUserId(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "User not found"));
        return issueTokenPair(user);
    }

    private TokenResponse issueTokenPair(User user) {
        String access = jwtService.generateAccessToken(user.getId(), user.getPhoneNumber());
        String refresh = jwtService.generateRefreshToken(user.getId());
        return new TokenResponse(access, refresh, user.getId().toString());
    }
}
