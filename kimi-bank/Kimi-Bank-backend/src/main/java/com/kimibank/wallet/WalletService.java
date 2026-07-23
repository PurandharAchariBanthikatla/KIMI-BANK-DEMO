package com.kimibank.wallet;

import com.kimibank.common.ApiException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Service
public class WalletService {

    private final WalletRepository walletRepository;
    private final WalletTransactionRepository transactionRepository;

    public WalletService(WalletRepository walletRepository, WalletTransactionRepository transactionRepository) {
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
    }

    public Wallet createWallet(UUID userId) {
        Wallet wallet = new Wallet();
        wallet.setUserId(userId);
        return walletRepository.save(wallet);
    }

    public Wallet getWalletOrThrow(UUID userId) {
        return walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Wallet not found"));
    }

    /**
     * Credits the wallet (e.g. top-up from linked bank account).
     * Idempotent on txnRef: replaying the same reference returns the original result without double-crediting.
     */
    @Transactional
    public WalletTransaction topUp(UUID userId, BigDecimal amount, String txnRef, String remarks) {
        validateAmount(amount);

        var existing = transactionRepository.findByTxnRef(txnRef);
        if (existing.isPresent()) return existing.get();

        Wallet wallet = walletRepository.findWithLockByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Wallet not found"));
        assertActive(wallet);

        BigDecimal newBalance = wallet.getBalance().add(amount);
        wallet.setBalance(newBalance);
        walletRepository.save(wallet);

        return recordTransaction(wallet.getId(), txnRef, "CREDIT", amount, newBalance,
                "TOPUP", null, remarks);
    }

    /**
     * Debits the wallet for a payment/transfer-out. Throws if funds are insufficient.
     * Idempotent on txnRef.
     */
    @Transactional
    public WalletTransaction debit(UUID userId, BigDecimal amount, String category, String counterparty,
                                    String txnRef, String remarks) {
        validateAmount(amount);

        var existing = transactionRepository.findByTxnRef(txnRef);
        if (existing.isPresent()) return existing.get();

        Wallet wallet = walletRepository.findWithLockByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Wallet not found"));
        assertActive(wallet);

        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Insufficient wallet balance");
        }

        BigDecimal newBalance = wallet.getBalance().subtract(amount);
        wallet.setBalance(newBalance);
        walletRepository.save(wallet);

        return recordTransaction(wallet.getId(), txnRef, "DEBIT", amount, newBalance,
                category, counterparty, remarks);
    }

    /**
     * Internal wallet-to-wallet transfer (e.g. P2P send). Debits sender, credits recipient atomically.
     * Uses two txnRefs so both legs are independently idempotent and independently visible in each ledger.
     */
    @Transactional
    public void transfer(UUID fromUserId, UUID toUserId, BigDecimal amount,
                          String debitTxnRef, String creditTxnRef, String remarks) {
        debit(fromUserId, amount, "TRANSFER", toUserId.toString(), debitTxnRef, remarks);
        topUpInternal(toUserId, amount, creditTxnRef, "TRANSFER", fromUserId.toString(), remarks);
    }

    private void topUpInternal(UUID userId, BigDecimal amount, String txnRef, String category,
                                String counterparty, String remarks) {
        var existing = transactionRepository.findByTxnRef(txnRef);
        if (existing.isPresent()) return;

        Wallet wallet = walletRepository.findWithLockByUserId(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Recipient wallet not found"));
        assertActive(wallet);

        BigDecimal newBalance = wallet.getBalance().add(amount);
        wallet.setBalance(newBalance);
        walletRepository.save(wallet);

        recordTransaction(wallet.getId(), txnRef, "CREDIT", amount, newBalance, category, counterparty, remarks);
    }

    public Page<WalletTransaction> getStatement(UUID userId, Pageable pageable) {
        Wallet wallet = getWalletOrThrow(userId);
        return transactionRepository.findByWalletIdOrderByCreatedAtDesc(wallet.getId(), pageable);
    }

    private WalletTransaction recordTransaction(UUID walletId, String txnRef, String type, BigDecimal amount,
                                                 BigDecimal balanceAfter, String category, String counterparty,
                                                 String remarks) {
        WalletTransaction txn = new WalletTransaction();
        txn.setWalletId(walletId);
        txn.setTxnRef(txnRef);
        txn.setType(type);
        txn.setAmount(amount);
        txn.setBalanceAfter(balanceAfter);
        txn.setCategory(category);
        txn.setCounterparty(counterparty);
        txn.setRemarks(remarks);
        return transactionRepository.save(txn);
    }

    private void validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Amount must be greater than zero");
        }
    }

    private void assertActive(Wallet wallet) {
        if (!"ACTIVE".equals(wallet.getStatus())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Wallet is frozen");
        }
    }
}
