package com.kimibank.account;

import com.kimibank.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.List;
import java.util.UUID;

@Service
public class AccountService {

    // MVP placeholder — real IFSC would come from the sponsor bank partnership.
    private static final String SPONSOR_IFSC = "KIMB0000001";

    private final AccountRepository accountRepository;
    private final SecureRandom random = new SecureRandom();

    public AccountService(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public Account createDefaultAccount(UUID userId) {
        Account account = new Account();
        account.setUserId(userId);
        account.setAccountNumber(generateAccountNumber());
        account.setIfscCode(SPONSOR_IFSC);
        account.setAccountType("SAVINGS");
        return accountRepository.save(account);
    }

    public List<Account> getAccountsForUser(UUID userId) {
        return accountRepository.findByUserId(userId);
    }

    public Account getAccountOrThrow(UUID accountId, UUID requestingUserId) {
        Account account = accountRepository.findById(accountId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Account not found"));
        if (!account.getUserId().equals(requestingUserId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Not authorized to view this account");
        }
        return account;
    }

    private String generateAccountNumber() {
        // 14-digit pseudo account number for MVP purposes.
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 14; i++) sb.append(random.nextInt(10));
        return sb.toString();
    }
}
