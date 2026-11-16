import type { ReactNode } from "react";
import { StatusRow, type Tone } from "../components/StatusRow";
import { useLaunchCount } from "../hooks/useLaunchCount";
import { isRunningInExtension } from "../services/extension";
import { getStore, type StorageBackend } from "../services/storage";

const BACKEND_LABEL: Record<StorageBackend, string> = {
  extension: "Extension storage",
  localStorage: "Browser localStorage",
  memory: "Memory only",
};

export function SystemCheck() {
  const inExtension = isRunningInExtension();
  const backend = getStore().backend;
  const launches = useLaunchCount();

  let saveTone: Tone;
  let saveValue: ReactNode;
  if (launches.status === "loading") {
    saveTone = "neutral";
    saveValue = "Checking…";
  } else if (launches.status === "error") {
    saveTone = "bad";
    saveValue = `Failed: ${launches.message}`;
  } else {
    saveTone = backend === "memory" ? "warn" : "good";
    saveValue = `Opened ${launches.count} ${launches.count === 1 ? "time" : "times"}`;
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
          tone={inExtension ? "good" : "neutral"}
          value={inExtension ? "Safari extension" : "Browser preview"}
        />
        <StatusRow
          label="Saving to"
          tone={backend === "memory" ? "warn" : "good"}
          value={BACKEND_LABEL[backend]}
        />
        <StatusRow label="Save test" tone={saveTone} value={saveValue} />
      </dl>
      <p className="card__hint">
        Quit Safari, open it again and click the toolbar icon. If the count above keeps going up,
        saved data is surviving restarts.
      </p>
    </section>
  );
}
