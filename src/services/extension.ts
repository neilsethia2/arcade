import type { MessageListener, WebExtensionApi } from "../types/webextension";

/** Message the toolbar button sends to find an arcade tab that is already open. */
export const FOCUS_MESSAGE = "arcade:focus";

/**
 * Returns the WebExtension API when the page is running inside the Safari
 * extension, or undefined when it is running as a normal web page (for
 * example `npm run dev` during development).
 */
export function getExtensionApi(): WebExtensionApi | undefined {
  const api = globalThis.browser ?? globalThis.chrome;
  return api?.runtime?.id ? api : undefined;
}

export function isRunningInExtension(): boolean {
  return getExtensionApi() !== undefined;
}

async function focusOwnTab(api: WebExtensionApi): Promise<void> {
  const tab = await api.tabs?.getCurrent();
  if (tab?.id === undefined) return;
  await api.tabs?.update(tab.id, { active: true });
  if (tab.windowId !== undefined) {
    await api.windows?.update(tab.windowId, { focused: true });
  }
}

/**
 * Lets the toolbar button bring this tab to the front instead of opening a
 * second copy of the arcade. Returns a function that removes the listener.
 */
export function listenForFocusRequests(): () => void {
  const api = getExtensionApi();
  if (!api) return () => {};

  const listener: MessageListener = (message, _sender, sendResponse) => {
    if (typeof message !== "object" || message === null) return;
    if ((message as { type?: unknown }).type !== FOCUS_MESSAGE) return;
    sendResponse({ ok: true });
    focusOwnTab(api).catch((error: unknown) => {
      console.warn("Safari Arcade: could not focus the arcade tab", error);
    });
  };

  api.runtime.onMessage.addListener(listener);
  return () => api.runtime.onMessage.removeListener(listener);
}
