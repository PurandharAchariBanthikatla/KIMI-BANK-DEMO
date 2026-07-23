package com.kimibank.account;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    public record AccountResponse(String id, String accountNumber, String ifscCode,
                                   String accountType, String status) {
        static AccountResponse from(Account a) {
            return new AccountResponse(a.getId().toString(), a.getAccountNumber(),
                    a.getIfscCode(), a.getAccountType(), a.getStatus());
        }
    }

    @GetMapping
    public List<AccountResponse> myAccounts() {
        UUID userId = currentUserId();
        return accountService.getAccountsForUser(userId).stream()
                .map(AccountResponse::from)
                .toList();
    }

    @GetMapping("/{accountId}")
    public AccountResponse getAccount(@PathVariable UUID accountId) {
        return AccountResponse.from(accountService.getAccountOrThrow(accountId, currentUserId()));
    }

    private UUID currentUserId() {
        return (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
