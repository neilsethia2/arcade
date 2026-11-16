/**
 * The bridge to the Mac app.
 *
 * When the arcade runs inside the Safari Arcade app (not in Safari), the app
 * exposes one message channel to the page, called "arcadeStorage". The page
 * sends it small requests and the Swift side reads or writes a file in
 * ~/Library/Application Support/Safari Arcade/. That file is what makes
 * high scores and settings survive quitting the app.
 *
 * Values travel as JSON text in both directions, so the Swift side never
 * has to understand the shape of a game's saved data.
 */

export type NativeStorageRequest =
  | { op: "get"; key: string }
  | { op: "set"; key: string; value: string }
  | { op: "remove"; key: string };

export interface NativeStorageBridge {
  /** Resolves with the app's reply, or rejects with the app's error message. */
  postMessage(request: NativeStorageRequest): Promise<unknown>;
}

interface WebKitGlobal {
  webkit?: {
    messageHandlers?: {
      arcadeStorage?: NativeStorageBridge;
    };
  };
}

/** Returns the bridge when running inside the Mac app, otherwise undefined. */
export function getNativeStorageBridge(): NativeStorageBridge | undefined {
  return (globalThis as WebKitGlobal).webkit?.messageHandlers?.arcadeStorage;
}

export function isRunningInNativeApp(): boolean {
  return getNativeStorageBridge() !== undefined;
}
