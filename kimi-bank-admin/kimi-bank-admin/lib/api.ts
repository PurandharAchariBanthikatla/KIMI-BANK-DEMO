// Talks to the KIMI BANK Spring Boot backend. Base URL is configurable so this
// works against local dev, staging, or prod without a code change.
const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8080";

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem("kimibank_admin_token");
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = getToken();

  let res: Response;
  try {
    res = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(init?.headers ?? {}),
      },
      cache: "no-store",
    });
  } catch {
    throw new Error(`Can't reach the API at ${API_BASE}. Is the backend running?`);
  }

  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(body || `${res.status} ${res.statusText}`);
  }

  return (await res.json()) as T;
}

// ---------- Customers ----------

export interface Customer {
  userId: string;
  name: string;
  phone: string;
  accountNumber: string;
  status: "ACTIVE" | "SUSPENDED" | "PENDING_KYC";
  walletBalance: number;
  createdAt: string;
}

export function getCustomers(params: { query?: string; page?: number } = {}) {
  const search = new URLSearchParams();
  if (params.query) search.set("query", params.query);
  search.set("page", String(params.page ?? 0));
  return request<{ items: Customer[]; totalPages: number }>(
    `/admin/customers?${search.toString()}`
  );
}

// ---------- Transactions ----------

export interface Transaction {
  transactionId: string;
  fromUserId: string;
  toUserId: string;
  amount: number;
  type: "TOPUP" | "PAYMENT" | "TRANSFER";
  status: "SUCCESS" | "PENDING" | "FAILED" | "FLAGGED";
  createdAt: string;
}

export function getTransactions(
  params: { status?: string; query?: string; page?: number } = {}
) {
  const search = new URLSearchParams();
  if (params.status) search.set("status", params.status);
  if (params.query) search.set("query", params.query);
  search.set("page", String(params.page ?? 0));
  return request<{ items: Transaction[]; totalPages: number }>(
    `/admin/transactions?${search.toString()}`
  );
}

// ---------- KYC queue ----------

export interface KycRequest {
  kycId: string;
  userId: string;
  name: string;
  documentType: "PAN" | "AADHAAR_XML" | "CKYC";
  status: "PENDING" | "APPROVED" | "REJECTED";
  submittedAt: string;
}

export function getKycQueue(params: { status?: string; page?: number } = {}) {
  const search = new URLSearchParams();
  search.set("status", params.status ?? "PENDING");
  search.set("page", String(params.page ?? 0));
  return request<{ items: KycRequest[]; totalPages: number }>(
    `/admin/kyc?${search.toString()}`
  );
}

export function updateKycStatus(kycId: string, status: "APPROVED" | "REJECTED") {
  return request<KycRequest>(`/admin/kyc/${kycId}`, {
    method: "PATCH",
    body: JSON.stringify({ status }),
  });
}
