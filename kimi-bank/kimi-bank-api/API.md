# KIMI BANK — Core API Reference (MVP)

Base URL (local): `http://localhost:8080`

All authenticated endpoints require:
```
Authorization: Bearer <accessToken>
```

---

## Auth

### `POST /auth/otp/request`
Request an OTP for signup or login.

```json
{ "phoneNumber": "9876543210", "purpose": "SIGNUP" }
```
`purpose`: `SIGNUP` | `LOGIN`

Response (dev mode includes the OTP for local testing; production never returns it):
```json
{ "message": "OTP sent", "devOtp": "482913" }
```

### `POST /auth/signup?otp=482913`
Completes signup after OTP verification. Auto-provisions a default account and wallet.

```json
{ "fullName": "Asha Rao", "phoneNumber": "9876543210" }
```
Response: `{ "accessToken", "refreshToken", "userId" }`

### `POST /auth/mpin/set` *(auth required)*
```json
{ "mpin": "482913" }
```

### `POST /auth/login`
```json
{ "phoneNumber": "9876543210", "mpin": "482913" }
```
Response: `{ "accessToken", "refreshToken", "userId" }`

### `POST /auth/refresh`
```json
{ "refreshToken": "<token>" }
```

---

## Accounts *(auth required)*

### `GET /accounts`
Returns the caller's accounts.

### `GET /accounts/{accountId}`
Returns a single account (403 if it doesn't belong to the caller).

---

## Wallet *(auth required)*

### `GET /wallet/balance`
```json
{ "walletId": "...", "balance": 1250.00, "currency": "INR", "status": "ACTIVE" }
```

### `POST /wallet/topup`
```json
{ "amount": 500.00, "txnRef": "TOPUP-<uuid>", "remarks": "optional" }
```
`txnRef` must be unique per attempt; replaying the same `txnRef` returns the original result instead of crediting twice (idempotent).

### `POST /wallet/pay`
```json
{ "amount": 250.00, "merchantId": "merchant@upi", "txnRef": "PAY-<uuid>", "remarks": "optional" }
```
Returns `422 Unprocessable Entity` if the wallet balance is insufficient.

### `POST /wallet/transfer`
```json
{ "toUserId": "<uuid>", "amount": 100.00, "txnRef": "XFER-<uuid>", "remarks": "optional" }
```
Debits the caller and credits the recipient atomically.

### `GET /wallet/statement?page=0&size=20`
Returns a page of transactions, most recent first.

---

## Error shape

All errors return:
```json
{
  "timestamp": "2026-07-22T10:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Human-readable explanation"
}
```

---

## Not yet implemented (roadmap)

These are the pieces from the original KIMI BANK vision that this MVP does **not** cover yet:
- Cards (virtual/physical), loans, investments (MF/FD/RD/SIP/gold)
- KYC/CKYC, liveness, AML/fraud services
- Admin, merchant, and support portals
- NEFT/IMPS/RTGS, standing instructions, beneficiary verification
- AI features (spending insights, fraud scoring, chat assistant)
- Notification service, rewards/cashback, budgeting/goals
- DevSecOps pipeline, observability stack, multi-service split (this MVP is a single deployable service, not 15–20 microservices)
- Actual RBI/NPCI licensing and sponsor-bank integration — required before any of this can move real money
