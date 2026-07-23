"use client";

import { useEffect, useState } from "react";
import Topbar from "@/components/Topbar";
import StatusPill, { Tone } from "@/components/StatusPill";
import { EmptyState, ErrorState, LoadingState, TableShell } from "@/components/DataView";
import { Transaction, getTransactions } from "@/lib/api";

const STATUS_META: Record<Transaction["status"], { label: string; tone: Tone }> = {
  SUCCESS: { label: "Success", tone: "credit" },
  PENDING: { label: "Pending", tone: "warn" },
  FAILED: { label: "Failed", tone: "neutral" },
  FLAGGED: { label: "Flagged", tone: "danger" },
};

const FILTERS: { value: string; label: string }[] = [
  { value: "", label: "All" },
  { value: "FLAGGED", label: "Flagged" },
  { value: "PENDING", label: "Pending" },
  { value: "FAILED", label: "Failed" },
];

function formatINR(amount: number) {
  return new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR" }).format(amount);
}

function isCredit(type: Transaction["type"]) {
  return type === "TOPUP";
}

export default function TransactionsPage() {
  const [txns, setTxns] = useState<Transaction[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("");
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setError(null);
    setTxns(null);

    const timeout = setTimeout(() => {
      getTransactions({ query, status: status || undefined })
        .then((res) => {
          if (!cancelled) setTxns(res.items);
        })
        .catch((err) => {
          if (!cancelled) setError(err instanceof Error ? err.message : "Unknown error");
        });
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timeout);
    };
  }, [query, status, reloadKey]);

  return (
    <>
      <Topbar
        title="Transactions"
        subtitle="Every top-up, payment, and transfer moving through the wallet ledger."
        search={query}
        onSearchChange={setQuery}
        searchPlaceholder="Search by transaction or user ID"
      />

      <div className="mx-8 mt-5 flex gap-2">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setStatus(f.value)}
            className={`rounded-md border px-3 py-1.5 text-sm font-medium transition-colors ${
              status === f.value
                ? "border-accent bg-accent-soft text-accent"
                : "border-border bg-surface text-ink-muted hover:bg-bg"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      <TableShell>
        {txns === null && !error && <LoadingState />}

        {error && <ErrorState message={error} onRetry={() => setReloadKey((k) => k + 1)} />}

        {txns && txns.length === 0 && !error && (
          <EmptyState
            title="No transactions match this view"
            description="Try clearing the filter or search — new activity lands here in real time."
          />
        )}

        {txns && txns.length > 0 && (
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-border text-xs uppercase tracking-wide text-ink-muted">
                <th className="px-6 py-3 font-medium">Transaction ID</th>
                <th className="px-6 py-3 font-medium">From → To</th>
                <th className="px-6 py-3 font-medium">Type</th>
                <th className="px-6 py-3 text-right font-medium">Amount</th>
                <th className="px-6 py-3 font-medium">Status</th>
                <th className="px-6 py-3 font-medium">When</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {txns.map((t) => {
                const meta = STATUS_META[t.status];
                const credit = isCredit(t.type);
                return (
                  <tr
                    key={t.transactionId}
                    className={`border-l-4 ${credit ? "border-l-credit" : "border-l-debit"}`}
                  >
                    <td className="px-6 py-4 font-mono text-ink-muted">{t.transactionId}</td>
                    <td className="px-6 py-4 font-mono text-ink-muted">
                      {t.fromUserId} → {t.toUserId}
                    </td>
                    <td className="px-6 py-4 text-ink">{t.type}</td>
                    <td
                      className={`tabular px-6 py-4 text-right font-mono ${
                        credit ? "text-credit" : "text-debit"
                      }`}
                    >
                      {credit ? "+" : "−"}
                      {formatINR(t.amount)}
                    </td>
                    <td className="px-6 py-4">
                      <StatusPill label={meta.label} tone={meta.tone} />
                    </td>
                    <td className="px-6 py-4 text-ink-muted">
                      {new Date(t.createdAt).toLocaleString("en-IN")}
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
