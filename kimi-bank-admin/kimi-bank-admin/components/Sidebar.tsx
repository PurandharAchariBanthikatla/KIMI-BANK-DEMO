"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/customers", label: "Customers", glyph: "C" },
  { href: "/transactions", label: "Transactions", glyph: "T" },
  { href: "/kyc", label: "KYC queue", glyph: "K" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex h-screen w-60 shrink-0 flex-col border-r border-border bg-surface">
      <div className="flex items-center gap-2 border-b border-border px-5 py-5">
        <div className="flex h-7 w-7 items-center justify-center rounded-md bg-ink font-display text-sm font-bold text-white">
          K
        </div>
        <div className="font-display text-[15px] font-bold tracking-tight text-ink">
          KIMI BANK
          <span className="ml-1.5 align-middle text-[10px] font-medium uppercase tracking-wider text-ink-muted">
            Admin
          </span>
        </div>
      </div>

      <nav className="flex-1 space-y-0.5 px-3 py-4">
        {NAV.map((item) => {
          const active = pathname?.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors ${
                active
                  ? "bg-accent-soft font-medium text-accent"
                  : "text-ink-muted hover:bg-bg hover:text-ink"
              }`}
            >
              <span
                className={`flex h-5 w-5 items-center justify-center rounded font-mono text-[11px] ${
                  active ? "bg-accent text-white" : "bg-bg text-ink-muted"
                }`}
              >
                {item.glyph}
              </span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-border px-5 py-4 text-[11px] leading-relaxed text-ink-muted">
        Ledger stripe on the left of every row shows money direction — teal in, terracotta out.
      </div>
    </aside>
  );
}
