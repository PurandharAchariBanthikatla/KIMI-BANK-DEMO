"use client";

import { useEffect, useState } from "react";
import Topbar from "@/components/Topbar";
import StatusPill, { Tone } from "@/components/StatusPill";
import { EmptyState, ErrorState, LoadingState, TableShell } from "@/components/DataView";
import { KycRequest, getKycQueue, updateKycStatus } from "@/lib/api";

const STATUS_META: Record<KycRequest["status"], { label: string; tone: Tone }> = {
  PENDING: { label: "Pending review", tone: "warn" },
  APPROVED: { label: "Approved", tone: "credit" },
  REJECTED: { label: "Rejected", tone: "danger" },
};

export default function KycQueuePage() {
  const [requests, setRequests] = useState<KycRequest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [actingOn, setActingOn] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setError(null);
    setRequests(null);

    getKycQueue({ status: "PENDING" })
      .then((res) => {
        if (!cancelled) setRequests(res.items);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Unknown error");
      });

    return () => {
      cancelled = true;
    };
  }, [reloadKey]);

  async function act(kycId: string, status: "APPROVED" | "REJECTED") {
    setActingOn(kycId);
    try {
      await updateKycStatus(kycId, status);
      setRequests((prev) => (prev ? prev.filter((r) => r.kycId !== kycId) : prev));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Couldn't update this request");
    } finally {
      setActingOn(null);
    }
  }

  return (
    <>
      <Topbar
        title="KYC queue"
        subtitle="Documents waiting on review before an account's wallet limits are raised."
      />

      <TableShell>
        {requests === null && !error && <LoadingState />}

        {error && <ErrorState message={error} onRetry={() => setReloadKey((k) => k + 1)} />}

        {requests && requests.length === 0 && !error && (
          <EmptyState
            title="Queue is clear"
            description="Nothing pending review right now — new submissions will show up here."
          />
        )}

        {requests && requests.length > 0 && (
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-border text-xs uppercase tracking-wide text-ink-muted">
                <th className="px-6 py-3 font-medium">Customer</th>
                <th className="px-6 py-3 font-medium">User ID</th>
                <th className="px-6 py-3 font-medium">Document</th>
                <th className="px-6 py-3 font-medium">Status</th>
                <th className="px-6 py-3 font-medium">Submitted</th>
                <th className="px-6 py-3 text-right font-medium">Review</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {requests.map((r) => {
                const meta = STATUS_META[r.status];
                const busy = actingOn === r.kycId;
                return (
                  <tr key={r.kycId} className="border-l-4 border-l-warn">
                    <td className="px-6 py-4 font-medium text-ink">{r.name}</td>
                    <td className="px-6 py-4 font-mono text-ink-muted">{r.userId}</td>
                    <td className="px-6 py-4 text-ink">{r.documentType}</td>
                    <td className="px-6 py-4">
                      <StatusPill label={meta.label} tone={meta.tone} />
                    </td>
                    <td className="px-6 py-4 text-ink-muted">
                      {new Date(r.submittedAt).toLocaleDateString("en-IN")}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        <button
                          disabled={busy}
                          onClick={() => act(r.kycId, "REJECTED")}
                          className="rounded-md border border-border bg-surface px-3 py-1.5 text-xs font-medium text-ink-muted hover:bg-danger-soft hover:text-danger disabled:opacity-50"
                        >
                          Reject
                        </button>
                        <button
                          disabled={busy}
                          onClick={() => act(r.kycId, "APPROVED")}
                          className="rounded-md bg-accent px-3 py-1.5 text-xs font-medium text-white hover:bg-[#0B6455] disabled:opacity-50"
                        >
                          {busy ? "Saving…" : "Approve"}
                        </button>
                      </div>
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
