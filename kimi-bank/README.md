# KIMI BANK — MVP

A working starter slice of the KIMI BANK vision: **auth (OTP + MPIN + JWT), accounts, and wallet**
(top-up, pay, peer transfer, statement) with a real Spring Boot backend, Postgres schema, and a
Flutter mobile app wired end-to-end.

This is **not** the full 250–400 screen / 100-microservice enterprise platform described in the
original scope doc — that's a multi-year, multi-team build, and a real UPI/banking product also
needs RBI/NPCI licensing and a sponsor-bank partnership, which no one can code their way around.
What's here is a solid, correct foundation you can extend module by module. See `docs/API.md` for
the "not yet implemented" roadmap.

## What's included

```
kimi-bank/
├── database/
│   └── schema.sql          # Postgres schema: users, otp, accounts, wallets, transactions, audit
├── backend/                # Spring Boot 3 + Java 21
│   └── src/main/java/com/kimibank/
│       ├── auth/           # signup, OTP, MPIN, JWT
│       ├── account/        # account provisioning + lookup
│       ├── wallet/         # balance, top-up, pay, transfer (locked + idempotent)
│       ├── security/       # JWT filter, security config
│       └── common/         # shared exception handling
├── mobile/                 # Flutter app
│   └── lib/
│       ├── screens/        # splash, welcome, signup, OTP, set-MPIN, login, dashboard, top-up, pay
│       ├── services/       # API client, auth service, wallet service
│       ├── models/         # wallet response models
│       └── theme/          # design tokens
├── docker-compose.yml       # local Postgres
└── docs/API.md              # API reference + roadmap
```

## Running the backend

**Requirements:** Java 21, Maven, Docker (for Postgres).

```bash
# 1. Start Postgres (auto-loads schema.sql on first run)
docker compose up -d postgres

# 2. Run the backend
cd backend
mvn spring-boot:run
```

The service starts on `http://localhost:8080`. Health check: `GET /actuator/health`.

OTP is in **dev mode** by default (`kimibank.otp.dev-mode: true` in `application.yml`) — the OTP
is returned directly in the API response instead of being sent by SMS, so you can test signup/login
without an SMS gateway. Wire up a real provider (e.g. MSG91, Twilio) in `OtpService` before going
anywhere near production, and turn dev-mode off.

**Before production use**, at minimum:
- Replace the hardcoded JWT secret in `application.yml` with a securely generated one from a secrets manager
- Turn off `kimibank.otp.dev-mode`
- Point `SPONSOR_IFSC` in `AccountService` at a real sponsor-bank partnership, or remove account
  provisioning until one exists
- Add rate limiting on `/auth/otp/request` and `/auth/login`

## Running the mobile app

**Requirements:** Flutter 3.x SDK.

```bash
cd mobile
flutter pub get
flutter run
```

By default `ApiClient.baseUrl` points at `http://10.0.2.2:8080`, which is the Android emulator's
alias for your host machine. If you're using:
- **iOS simulator** → change to `http://localhost:8080`
- **Physical device** → change to your machine's LAN IP, e.g. `http://192.168.1.20:8080`

That's the only thing you need to change to get the app talking to your local backend.

## Trying the flow end-to-end

1. Launch the app → **Create account** → enter name + phone
2. Note the "Dev mode OTP" shown on screen (or check backend logs) → enter it
3. Set a 6-digit MPIN (enter twice to confirm)
4. You land on the dashboard with a ₹0 balance
5. **Add money** to top up the wallet
6. **Pay** to send money out, or hit `/wallet/transfer` directly (no UI screen yet) to send to
   another user by their `userId`

## Suggested next build order

1. **KYC** — PAN/CKYC capture screens + a `kyc-service` that gates `accounts.status` before wallet
   limits are raised
2. **Cards** — virtual card issuance tied to the wallet, freeze/unfreeze, spend limits
3. **Beneficiaries + NEFT/IMPS** — extend `wallet-service` or split into a dedicated `payment-service`
   once transaction volume/complexity justifies the split
4. **Admin portal** — read-only views over the existing tables (customer list, transaction monitor,
   KYC queue) before building write-heavy admin actions
5. Split into microservices only once a module's scaling or ownership needs actually diverge from
   the others — this monolith-first structure is deliberate for an MVP.
