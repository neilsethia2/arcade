import type { ReactNode } from "react";
import { StatusRow, type Tone } from "../components/StatusRow";
import { useDiagnostics } from "../hooks/useDiagnostics";
import { getEnvironment, type Environment } from "../services/diagnostics";
import { getStore, type StorageBackend } from "../services/storage";

const ENVIRONMENT_LABEL: Record<Environment, string> = {
  native: "Mac app",
  extension: "Safari extension",
  browser: "Browser preview",
};

const BACKEND_LABEL: Record<StorageBackend, string> = {
  native: "A file on this Mac",
  extension: "Extension storage",
  localStorage: "Browser localStorage",
  memory: "Memory only",
};

/** Only the Mac app's file has been shown to survive a restart on a real Mac. */
const BACKEND_TONE: Record<StorageBackend, Tone> = {
  native: "good",
  extension: "warn",
  localStorage: "neutral",
  memory: "warn",
};

const HINT: Record<Environment, string> = {
  native:
    "Quit Safari Arcade and open it again. If the count above keeps going up, saved data is surviving restarts.",
  extension:
    "Safari forgets an unsigned extension's saved data when it quits, so this count starts again each time. Open the Safari Arcade app to keep scores.",
  browser: "This is a development preview. Saved data stays in this browser only.",
};

export function SystemCheck() {
  const environment = getEnvironment();
  const backend = getStore().backend;
  const report = useDiagnostics();

  let saveTone: Tone;
  let saveValue: ReactNode;
  if (!report) {
    saveTone = "neutral";
    saveValue = "Checking…";
  } else if (report.error !== null || report.launchCount === null) {
    saveTone = "bad";
    saveValue = `Failed: ${report.error ?? "nothing was read back"}`;
  } else {
    saveTone = BACKEND_TONE[backend];
    saveValue = `Opened ${report.launchCount} ${report.launchCount === 1 ? "time" : "times"}`;
  }

  return (
    <section className="card" aria-labelledby="system-check-title">
      <h2 id="system-check-title" className="card__title">
        System check
      </h2>
      <p className="card__lead">
        The games arrive in the next milestones. This screen confirms the foundations work.
      </p>
      <dl className="status-list">
        <StatusRow
          label="Running in"
          tone={environment === "native" ? "good" : "neutral"}
          value={ENVIRONMENT_LABEL[environment]}
        />
        <StatusRow label="Saving to" tone={BACKEND_TONE[backend]} value={BACKEND_LABEL[backend]} />
        <StatusRow label="Save test" tone={saveTone} value={saveValue} />
      </dl>
      <p className="card__hint">{HINT[environment]}</p>
    </section>
  );
}
