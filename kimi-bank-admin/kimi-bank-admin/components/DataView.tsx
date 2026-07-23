import { ReactNode } from "react";

export function LoadingState({ rows = 6 }: { rows?: number }) {
  return (
    <div className="divide-y divide-border">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 px-6 py-4">
          <div className="h-4 w-4 animate-pulse rounded bg-border" />
          <div className="h-4 w-40 animate-pulse rounded bg-border" />
          <div className="h-4 w-24 animate-pulse rounded bg-border" />
          <div className="ml-auto h-4 w-20 animate-pulse rounded bg-border" />
        </div>
      ))}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-16 text-center">
      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-danger-soft font-display text-danger">
        !
      </div>
      <div>
        <p className="text-sm font-medium text-ink">Couldn't load this data</p>
        <p className="mt-1 max-w-sm text-sm text-ink-muted">{message}</p>
      </div>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-1 rounded-md border border-border bg-surface px-3 py-1.5 text-sm font-medium text-ink hover:bg-bg"
        >
          Retry
        </button>
      )}
    </div>
  );
}

export function EmptyState({ title, description }: { title: string; description: string }) {
  return (
    <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-bg font-display text-ink-muted">
        —
      </div>
      <p className="text-sm font-medium text-ink">{title}</p>
      <p className="max-w-sm text-sm text-ink-muted">{description}</p>
    </div>
  );
}

export function TableShell({ children }: { children: ReactNode }) {
  return (
    <div className="mx-8 mt-6 overflow-hidden rounded-lg border border-border bg-surface">
      {children}
    </div>
  );
}
