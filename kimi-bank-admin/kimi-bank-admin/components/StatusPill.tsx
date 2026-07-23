type Tone = "credit" | "debit" | "warn" | "danger" | "neutral";

const TONE_STYLES: Record<Tone, string> = {
  credit: "bg-accent-soft text-accent",
  debit: "bg-[#FBEAE3] text-debit",
  warn: "bg-warn-soft text-warn",
  danger: "bg-danger-soft text-danger",
  neutral: "bg-[#EDEFF2] text-ink-muted",
};

const DOT_STYLES: Record<Tone, string> = {
  credit: "bg-accent",
  debit: "bg-debit",
  warn: "bg-warn",
  danger: "bg-danger",
  neutral: "bg-ink-muted",
};

export default function StatusPill({ label, tone }: { label: string; tone: Tone }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${TONE_STYLES[tone]}`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${DOT_STYLES[tone]}`} />
      {label}
    </span>
  );
}

export type { Tone };
