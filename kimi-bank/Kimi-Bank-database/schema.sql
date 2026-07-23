-- =====================================================================
-- KIMI BANK — MVP Core Schema (Auth + Accounts + Wallet)
-- Postgres 15+
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- AUTH / IDENTITY
-- ---------------------------------------------------------------------

CREATE TABLE users (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name         VARCHAR(120) NOT NULL,
    email             VARCHAR(160) UNIQUE,
    phone_number      VARCHAR(15)  NOT NULL UNIQUE,
    password_hash     VARCHAR(255),           -- bcrypt, nullable if OTP-only user
    mpin_hash         VARCHAR(255),           -- bcrypt of 4/6 digit MPIN
    kyc_status        VARCHAR(20)  NOT NULL DEFAULT 'PENDING', -- PENDING, IN_REVIEW, VERIFIED, REJECTED
    status            VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE, SUSPENDED, CLOSED
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE devices (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_fingerprint VARCHAR(255) NOT NULL,
    device_name       VARCHAR(120),
    platform          VARCHAR(20),            -- ANDROID, IOS, WEB
    is_trusted        BOOLEAN NOT NULL DEFAULT false,
    last_seen_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, device_fingerprint)
);

CREATE TABLE sessions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id         UUID REFERENCES devices(id) ON DELETE SET NULL,
    refresh_token_hash VARCHAR(255) NOT NULL,
    issued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at        TIMESTAMPTZ NOT NULL,
    revoked           BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE otp_verifications (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number      VARCHAR(15) NOT NULL,
    otp_hash          VARCHAR(255) NOT NULL,
    purpose           VARCHAR(30) NOT NULL,   -- LOGIN, SIGNUP, RESET_MPIN, TXN_CONFIRM
    attempts          INT NOT NULL DEFAULT 0,
    max_attempts      INT NOT NULL DEFAULT 5,
    expires_at        TIMESTAMPTZ NOT NULL,
    consumed          BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_otp_phone_purpose ON otp_verifications(phone_number, purpose);

-- ---------------------------------------------------------------------
-- ACCOUNTS
-- ---------------------------------------------------------------------

CREATE TABLE accounts (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_number    VARCHAR(20) NOT NULL UNIQUE,
    ifsc_code         VARCHAR(11) NOT NULL,
    account_type      VARCHAR(20) NOT NULL DEFAULT 'SAVINGS', -- SAVINGS, CURRENT
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE beneficiaries (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    beneficiary_name  VARCHAR(120) NOT NULL,
    account_number    VARCHAR(20),
    ifsc_code         VARCHAR(11),
    upi_id            VARCHAR(60),
    nickname          VARCHAR(60),
    is_verified       BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- WALLET
-- ---------------------------------------------------------------------

CREATE TABLE wallets (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance           NUMERIC(18,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency          VARCHAR(3) NOT NULL DEFAULT 'INR',
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, FROZEN
    version           BIGINT NOT NULL DEFAULT 0,             -- optimistic locking
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE wallet_transactions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id         UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    txn_ref           VARCHAR(40) NOT NULL UNIQUE,
    type              VARCHAR(20) NOT NULL,   -- CREDIT, DEBIT
    amount            NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    balance_after     NUMERIC(18,2) NOT NULL,
    category          VARCHAR(30),            -- TOPUP, TRANSFER, PAYMENT, REFUND, REWARD
    counterparty      VARCHAR(120),
    status            VARCHAR(20) NOT NULL DEFAULT 'SUCCESS', -- PENDING, SUCCESS, FAILED, REVERSED
    remarks           VARCHAR(255),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_wallet_txn_wallet_id ON wallet_transactions(wallet_id, created_at DESC);

-- ---------------------------------------------------------------------
-- AUDIT
-- ---------------------------------------------------------------------

CREATE TABLE audit_logs (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID REFERENCES users(id) ON DELETE SET NULL,
    action            VARCHAR(60) NOT NULL,
    entity_type       VARCHAR(60),
    entity_id         UUID,
    ip_address        VARCHAR(45),
    metadata          JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- SEED DATA (dev only)
-- ---------------------------------------------------------------------
-- INSERT INTO users (full_name, phone_number, password_hash, kyc_status)
-- VALUES ('Test User', '9999999999', crypt('Passw0rd!', gen_salt('bf')), 'VERIFIED');
