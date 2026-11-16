import type { StorageArea } from "../types/webextension";
import { getExtensionApi } from "./extension";

/**
 * Persistence for the whole arcade: high scores, settings, favourites.
 *
 * Why not just use localStorage? Inside Safari the extension page lives at
 * an address like safari-web-extension://<id>/, and localStorage is tied to
 * that address. The extension's own storage area (browser.storage.local)
 * belongs to the extension itself, so it is the safer home for saved data.
 * localStorage is only the fallback for running the app outside Safari
 * during development.
 *
 * Every game talks to this one interface and never to a storage API
 * directly, so game code stays independent of where the data lives.
 */
export interface KeyValueStore {
  /** Which backend is in use, shown on the diagnostics screen. */
  readonly backend: StorageBackend;
  get<T>(key: string, fallback: T): Promise<T>;
  set<T>(key: string, value: T): Promise<void>;
  remove(key: string): Promise<void>;
}

export type StorageBackend = "extension" | "localStorage" | "memory";

const PREFIX = "arcade:";

/** Backed by the extension's own storage area. Values are stored as JSON-safe data. */
export function createExtensionStore(area: StorageArea): KeyValueStore {
  return {
    backend: "extension",
    async get<T>(key: string, fallback: T): Promise<T> {
      const fullKey = PREFIX + key;
      const result = await area.get(fullKey);
      const value = result[fullKey];
      return value === undefined ? fallback : (value as T);
    },
    async set<T>(key: string, value: T): Promise<void> {
      await area.set({ [PREFIX + key]: value });
    },
    async remove(key: string): Promise<void> {
      await area.remove(PREFIX + key);
    },
  };
}

/** The subset of the DOM Storage interface we need, so tests can pass a fake. */
export interface StringStorage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

/** Backed by window.localStorage. Values are stored as JSON text. */
export function createLocalStorageStore(storage: StringStorage): KeyValueStore {
  return {
    backend: "localStorage",
    async get<T>(key: string, fallback: T): Promise<T> {
      const raw = storage.getItem(PREFIX + key);
      if (raw === null) return fallback;
      try {
        return JSON.parse(raw) as T;
      } catch {
        // Corrupt entry: behave as if nothing was saved rather than crash a game.
        return fallback;
      }
    },
    async set<T>(key: string, value: T): Promise<void> {
      storage.setItem(PREFIX + key, JSON.stringify(value));
    },
    async remove(key: string): Promise<void> {
      storage.removeItem(PREFIX + key);
    },
  };
}

/** Keeps data only until the page closes. Last resort if nothing else works. */
export function createMemoryStore(): KeyValueStore {
  const data = new Map<string, unknown>();
  return {
    backend: "memory",
    async get<T>(key: string, fallback: T): Promise<T> {
      return data.has(key) ? (data.get(key) as T) : fallback;
    },
    async set<T>(key: string, value: T): Promise<void> {
      data.set(key, value);
    },
    async remove(key: string): Promise<void> {
      data.delete(key);
    },
  };
}

function detectStore(): KeyValueStore {
  const area = getExtensionApi()?.storage?.local;
  if (area) return createExtensionStore(area);

  try {
    const storage = globalThis.localStorage;
    const probe = PREFIX + "__probe__";
    storage.setItem(probe, "1");
    storage.removeItem(probe);
    return createLocalStorageStore(storage);
  } catch {
    return createMemoryStore();
  }
}

let shared: KeyValueStore | undefined;

/** The one store the whole app shares. */
export function getStore(): KeyValueStore {
  shared ??= detectStore();
  return shared;
}
