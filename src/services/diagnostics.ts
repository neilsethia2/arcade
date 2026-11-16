import { isRunningInExtension } from "./extension";
import { isRunningInNativeApp } from "./native";
import { getStore, type StorageBackend } from "./storage";

export type Environment = "native" | "extension" | "browser";

/**
 * A small health report about the running arcade.
 *
 * It is shown on the system check screen, and it is also published on
 * `window.__arcadeDiagnostics` so the Mac app can read it during its
 * automated self-test (see macos-app/App/SelfTest.swift). That test runs on
 * GitHub's Mac build machine after every build and fails the build if the
 * page does not load or saving does not work.
 */
export interface Diagnostics {
  /** True once the save test has finished, whether it passed or failed. */
  ready: boolean;
  environment: Environment;
  storage: StorageBackend;
  /** How many times the arcade has been opened, read back from storage. */
  launchCount: number | null;
  /** Why the save test failed, if it did. */
  error: string | null;
}

declare global {
  // eslint-disable-next-line no-var
  var __arcadeDiagnostics: Diagnostics | undefined;
}

const LAUNCH_COUNT_KEY = "diagnostics.launchCount";

export function getEnvironment(): Environment {
  if (isRunningInNativeApp()) return "native";
  if (isRunningInExtension()) return "extension";
  return "browser";
}

let pending: Promise<Diagnostics> | undefined;

async function run(): Promise<Diagnostics> {
  const store = getStore();
  const report: Diagnostics = {
    ready: false,
    environment: getEnvironment(),
    storage: store.backend,
    launchCount: null,
    error: null,
  };
  globalThis.__arcadeDiagnostics = report;

  try {
    const next = (await store.get(LAUNCH_COUNT_KEY, 0)) + 1;
    await store.set(LAUNCH_COUNT_KEY, next);
    // Read it back rather than trusting the write, so the report only says
    // saving works when the value really came out of storage.
    report.launchCount = await store.get(LAUNCH_COUNT_KEY, 0);
  } catch (error) {
    report.error = error instanceof Error ? error.message : String(error);
  }

  report.ready = true;
  return report;
}

/**
 * Runs the save test once per page load and returns the report. Calling it
 * again returns the same result, so the launch counter only goes up by one
 * however many parts of the app ask.
 */
export function runDiagnostics(): Promise<Diagnostics> {
  pending ??= run();
  return pending;
}
