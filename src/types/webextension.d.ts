/**
 * The small slice of the WebExtension API that Safari Arcade uses.
 *
 * Safari exposes this as `browser` (and also as `chrome`). Declaring only
 * what we call keeps us honest about which APIs the app depends on, which
 * matters because not every Chrome extension API exists in Safari.
 */

export interface StorageArea {
  get(keys?: string | string[] | null): Promise<Record<string, unknown>>;
  set(items: Record<string, unknown>): Promise<void>;
  remove(keys: string | string[]): Promise<void>;
}

export interface ExtensionTab {
  id?: number;
  windowId?: number;
}

export type MessageListener = (
  message: unknown,
  sender: unknown,
  sendResponse: (response?: unknown) => void,
) => boolean | void;

export interface WebExtensionApi {
  runtime: {
    id?: string;
    getURL(path: string): string;
    sendMessage(message: unknown): Promise<unknown>;
    onMessage: {
      addListener(listener: MessageListener): void;
      removeListener(listener: MessageListener): void;
    };
  };
  storage?: {
    local?: StorageArea;
  };
  tabs?: {
    getCurrent(): Promise<ExtensionTab | undefined>;
    update(tabId: number, props: { active?: boolean }): Promise<ExtensionTab | undefined>;
  };
  windows?: {
    update(windowId: number, props: { focused?: boolean }): Promise<unknown>;
  };
}

declare global {
  // eslint-disable-next-line no-var
  var browser: WebExtensionApi | undefined;
  // eslint-disable-next-line no-var
  var chrome: WebExtensionApi | undefined;
  const __APP_VERSION__: string;
}
