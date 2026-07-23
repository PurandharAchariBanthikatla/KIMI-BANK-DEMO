# KIMI BANK Admin

Next.js 15 + TypeScript + Tailwind ops console. Three pages, each making real fetch calls to the
Spring Boot backend — no mock data.

```
kimi-bank-admin/
├── app/
│   ├── layout.tsx        # shell: sidebar + fonts
│   ├── customers/        # customer list — search, status, wallet balance
│   ├── transactions/     # transaction monitor — filter by status
│   └── kyc/               # KYC queue — approve/reject pending submissions
├── components/            # Sidebar, Topbar, StatusPill, loading/error/empty states
└── lib/api.ts              # typed fetch client against the backend
```

## Design

A ledger-stripe on the left of every row shows money direction at a glance — teal for money in,
terracotta for money out, amber for anything pending review. All IDs and amounts are set in
monospace with tabular figures, since this page is read by people cross-checking numbers.

## Running it

```bash
npm install
cp .env.local.example .env.local   # point at your backend
npm run dev
```

Opens on `http://localhost:3000`, redirects to `/customers`.

Admin requests read a bearer token from `localStorage["kimibank_admin_token"]`. There's no login
screen yet — set it manually in devtools while an admin auth flow is still on the roadmap:

```js
localStorage.setItem("kimibank_admin_token", "<a valid admin JWT>");
```

## Backend endpoints this expects

None of these exist in `backend/` yet — the current Spring Boot service only covers auth,
accounts, and wallet. Add an `admin` package with:

| Method  | Path                       | Returns                                              |
|---------|-----------------------------|-------------------------------------------------------|
| `GET`   | `/admin/customers`          | `{ items: Customer[], totalPages }`, filterable by `query`, `page` |
| `GET`   | `/admin/transactions`       | `{ items: Transaction[], totalPages }`, filterable by `status`, `query`, `page` |
| `GET`   | `/admin/kyc`                | `{ items: KycRequest[], totalPages }`, filterable by `status`, `page` |
| `PATCH` | `/admin/kyc/{kycId}`        | Updates KYC status, body `{ status: "APPROVED" \| "REJECTED" }` |

Field shapes are in `lib/api.ts`. All four should require an admin-role JWT — this UI has no
concept of what's safe to call without one, so that check has to live server-side.

## Before production

- [ ] Real admin login (this currently expects a token to already be in `localStorage`)
- [ ] Role check on every `/admin/*` route in the backend, not just a valid JWT
- [ ] Audit log on KYC approve/reject actions — who reviewed what, and when
- [ ] Pagination controls in the UI (the API already returns `totalPages`, wiring is pending)
