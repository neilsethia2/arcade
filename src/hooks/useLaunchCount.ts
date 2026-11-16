import { useEffect, useState } from "react";
import { getStore } from "../services/storage";

export type LaunchCount =
  | { status: "loading" }
  | { status: "ready"; count: number }
  | { status: "error"; message: string };

const KEY = "diagnostics.launchCount";

// React's StrictMode runs effects twice in development. Sharing one promise
// per page load makes sure the counter still only goes up by one.
let pending: Promise<number> | undefined;

function countThisLaunch(): Promise<number> {
  pending ??= (async () => {
    const store = getStore();
    const next = (await store.get(KEY, 0)) + 1;
    await store.set(KEY, next);
    // Read it back rather than trusting the write, so the screen only says
    // "working" when the value really came out of storage.
    return store.get(KEY, 0);
  })();
  return pending;
}

/**
 * Counts how many times the arcade has been opened. The number only keeps
 * climbing across Safari restarts if saving really works, which makes it a
 * simple end-to-end test of persistence.
 */
export function useLaunchCount(): LaunchCount {
  const [state, setState] = useState<LaunchCount>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;
    countThisLaunch().then(
      (count) => {
        if (!cancelled) setState({ status: "ready", count });
      },
      (error: unknown) => {
        if (!cancelled) {
          setState({
            status: "error",
            message: error instanceof Error ? error.message : String(error),
          });
        }
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  return state;
}
