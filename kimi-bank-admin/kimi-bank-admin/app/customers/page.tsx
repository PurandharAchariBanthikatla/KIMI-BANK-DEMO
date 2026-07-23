"use client";

import { useEffect, useMemo, useState } from "react";
import Topbar from "@/components/Topbar";
import StatusPill, { Tone } from "@/components/StatusPill";
import { EmptyState, ErrorState, LoadingState, TableShell } from "@/components/DataView";
import { Customer, getCustomers } from "@/lib/api";

const STATUS_TONE: Record<Customer["status"], { label: string; tone: Tone }> = {
  ACTIVE: { label: "Active", tone: "credit" },
  PENDING_KYC: { label: "Pending KYC", tone: "warn" },
  SUSPENDED: { label: "Suspended", tone: "danger" },
};

function formatINR(amount: number) {
  return new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR" }).format(amount);
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setError(null);
    setCustomers(null);

    const timeout = setTimeout(() => {
      getCustomers({ query })
        .then((res) => {
          if (!cancelled) setCustomers(res.items);
        })
        .catch((err) => {
          if (!cancelled) setError(err instanceof Error ? err.message : "Unknown error");
        });
    }, 250); // debounce search

    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [query, reloadKey]);

  const rowStripe = useMemo(
    () => (status: Customer["status"]) =>
      status === "SUSPENDED" ? "border-l-danger" : status === "PENDING_KYC" ? "border-l-warn" : "border-l-accent",
    []
  );

  return (
    <>
      <Topbar
        title="Customers"
        subtitle="Every account provisioned on KIMI BANK, searchable by name, phone, or account number."
        search={query}
        onSearchChange={setQuery}
        searchPlaceholder="Search name, phone, or account no."
      />

      <TableShell>
        {customers === null && !error && <LoadingState />}

        {error && <ErrorState message={error} onRetry={() => setReloadKey((k) => k + 1)} />}

        {customers && customers.length === 0 && !error && (
          <EmptyState
            title={query ? "No customers match that search" : "No customers yet"}
            description={
              query
                ? "Try a different name, phone number, or account number."
                : "New signups will appear here as soon as they complete onboarding."
            }
          />
        )}

        {customers && customers.length > 0 && (
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-border text-xs uppercase tracking-wide text-ink-muted">
                <th className="px-6 py-3 font-medium">Customer</th>
                <th className="px-6 py-3 font-medium">Phone</th>
                <th className="px-6 py-3 font-medium">Account no.</th>
                <th className="px-6 py-3 font-medium">Status</th>
                <th className="px-6 py-3 text-right font-medium">Wallet balance</th>
                <th className="px-6 py-3 font-medium">Joined</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {customers.map((c) => {
                const meta = STATUS_TONE[c.status];
                return (
                  <tr key={c.userId} className={`border-l-4 ${rowStripe(c.status)}`}>
                    <td className="px-6 py-4 font-medium text-ink">{c.name}</td>
                    <td className="px-6 py-4 font-mono text-ink-muted">{c.phone}</td>
                    <td className="px-6 py-4 font-mono text-ink-muted">{c.accountNumber}</td>
                    <td className="px-6 py-4">
                      <StatusPill label={meta.label} tone={meta.tone} />
                    </td>
                    <td className="tabular px-6 py-4 text-right font-mono text-ink">
                      {formatINR(c.walletBalance)}
                    </td>
                    <td className="px-6 py-4 text-ink-muted">
                      {new Date(c.createdAt).toLocaleDateString("en-IN")}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </TableShell>
    </>
  );
}
