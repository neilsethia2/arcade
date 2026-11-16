import { useEffect, useState } from "react";
import { runDiagnostics, type Diagnostics } from "../services/diagnostics";

/** The diagnostics report, or undefined while the save test is still running. */
export function useDiagnostics(): Diagnostics | undefined {
  const [report, setReport] = useState<Diagnostics | undefined>(undefined);

  useEffect(() => {
    let cancelled = false;
    void runDiagnostics().then((result) => {
      if (!cancelled) setReport(result);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return report;
}
