import type { ReactNode } from "react";

export type Tone = "good" | "warn" | "bad" | "neutral";

interface StatusRowProps {
  label: string;
  value: ReactNode;
  tone: Tone;
}

/** One label and value line with a coloured dot showing whether it is healthy. */
export function StatusRow({ label, value, tone }: StatusRowProps) {
  return (
    <div className="status-row">
      <dt className="status-row__label">{label}</dt>
      <dd className="status-row__value">
        <span className={`status-dot status-dot--${tone}`} aria-hidden="true" />
        {value}
      </dd>
    </div>
  );
}
