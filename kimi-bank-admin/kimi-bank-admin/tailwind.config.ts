import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        bg: "#F5F6F8",
        surface: "#FFFFFF",
        ink: "#12161C",
        "ink-muted": "#5B6472",
        border: "#E2E5EA",
        accent: "#0E7C66",
        "accent-soft": "#E6F4F1",
        credit: "#0E7C66",
        debit: "#B3401F",
        warn: "#B45309",
        "warn-soft": "#FBEEDC",
        danger: "#B3261E",
        "danger-soft": "#FBEAE8",
      },
      fontFamily: {
        display: ["var(--font-display)"],
        body: ["var(--font-body)"],
        mono: ["var(--font-mono)"],
      },
    },
  },
  plugins: [],
};

export default config;
