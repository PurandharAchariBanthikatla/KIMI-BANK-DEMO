package com.kimibank.wallet;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    public record TopUpRequest(@NotNull @Positive BigDecimal amount,
                                @NotBlank String txnRef,
                                String remarks) {}

    public record PayRequest(@NotNull @Positive BigDecimal amount,
                              @NotBlank String merchantId,
                              @NotBlank String txnRef,
                              String remarks) {}

    public record TransferRequest(@NotBlank String toUserId,
                                   @NotNull @Positive BigDecimal amount,
                                   @NotBlank String txnRef,
                                   String remarks) {}

    public record BalanceResponse(String walletId, BigDecimal balance, String currency, String status) {}

    public record TxnResponse(String id, String type, BigDecimal amount, BigDecimal balanceAfter,
                               String category, String counterparty, String status, String createdAt) {
        static TxnResponse from(WalletTransaction t) {
            return new TxnResponse(t.getId().toString(), t.getType(), t.getAmount(), t.getBalanceAfter(),
                    t.getCategory(), t.getCounterparty(), t.getStatus(), t.getCreatedAt().toString());
        }
    }

    @GetMapping("/balance")
    public BalanceResponse balance() {
        Wallet w = walletService.getWalletOrThrow(currentUserId());
        return new BalanceResponse(w.getId().toString(), w.getBalance(), w.getCurrency(), w.getStatus());
    }

    @PostMapping("/topup")
    public TxnResponse topUp(@RequestBody TopUpRequest request) {
        var txn = walletService.topUp(currentUserId(), request.amount(), request.txnRef(), request.remarks());
        return TxnResponse.from(txn);
    }

    @PostMapping("/pay")
    public TxnResponse pay(@RequestBody PayRequest request) {
        var txn = walletService.debit(currentUserId(), request.amount(), "PAYMENT",
                request.merchantId(), request.txnRef(), request.remarks());
        return TxnResponse.from(txn);
    }

    @PostMapping("/transfer")
    public void transfer(@RequestBody TransferRequest request) {
        UUID toUserId = UUID.fromString(request.toUserId());
        walletService.transfer(currentUserId(), toUserId, request.amount(),
                request.txnRef() + "-debit", request.txnRef() + "-credit", request.remarks());
    }

    @GetMapping("/statement")
    public List<TxnResponse> statement(@RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "20") int size) {
        return walletService.getStatement(currentUserId(), PageRequest.of(page, size))
                .map(TxnResponse::from)
                .toList();
    }

    private UUID currentUserId() {
        return (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}
