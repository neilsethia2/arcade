import { describe, expect, it } from "vitest";
import type { StorageArea } from "../types/webextension";
import {
  createExtensionStore,
  createLocalStorageStore,
  createMemoryStore,
  type KeyValueStore,
  type StringStorage,
} from "./storage";

function fakeExtensionArea(): StorageArea & { data: Record<string, unknown> } {
  const data: Record<string, unknown> = {};
  return {
    data,
    async get(keys) {
      const list = keys == null ? Object.keys(data) : Array.isArray(keys) ? keys : [keys];
      const out: Record<string, unknown> = {};
      for (const key of list) {
        // Round-trip through JSON like a real extension storage area does.
        if (key in data) out[key] = JSON.parse(JSON.stringify(data[key]));
      }
      return out;
    },
    async set(items) {
      for (const [key, value] of Object.entries(items)) {
        data[key] = JSON.parse(JSON.stringify(value));
      }
    },
    async remove(keys) {
      for (const key of Array.isArray(keys) ? keys : [keys]) delete data[key];
    },
  };
}

function fakeLocalStorage(): StringStorage & { data: Map<string, string> } {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => void data.set(key, value),
    removeItem: (key) => void data.delete(key),
  };
}

const backends: Array<[string, () => KeyValueStore]> = [
  ["extension storage", () => createExtensionStore(fakeExtensionArea())],
  ["localStorage", () => createLocalStorageStore(fakeLocalStorage())],
  ["memory", () => createMemoryStore()],
];

describe.each(backends)("KeyValueStore backed by %s", (_name, makeStore) => {
  it("returns the fallback when nothing was saved", async () => {
    const store = makeStore();
    expect(await store.get("missing", 42)).toBe(42);
  });

  it("saves and reads back numbers, strings and objects", async () => {
    const store = makeStore();
    await store.set("score", 1200);
    await store.set("name", "Tetris");
    await store.set("settings", { sound: false, theme: "dark", recent: ["snake"] });

    expect(await store.get("score", 0)).toBe(1200);
    expect(await store.get("name", "")).toBe("Tetris");
    expect(await store.get("settings", {})).toEqual({
      sound: false,
      theme: "dark",
      recent: ["snake"],
    });
  });

  it("keeps falsy values instead of treating them as missing", async () => {
    const store = makeStore();
    await store.set("zero", 0);
    await store.set("off", false);
    await store.set("empty", "");

    expect(await store.get("zero", 99)).toBe(0);
    expect(await store.get("off", true)).toBe(false);
    expect(await store.get("empty", "fallback")).toBe("");
  });

  it("overwrites an existing value", async () => {
    const store = makeStore();
    await store.set("score", 10);
    await store.set("score", 20);
    expect(await store.get("score", 0)).toBe(20);
  });

  it("removes a value", async () => {
    const store = makeStore();
    await store.set("score", 10);
    await store.remove("score");
    expect(await store.get("score", -1)).toBe(-1);
  });
});

describe("key namespacing", () => {
  it("prefixes extension storage keys so they cannot clash with other data", async () => {
    const area = fakeExtensionArea();
    await createExtensionStore(area).set("score", 1);
    expect(Object.keys(area.data)).toEqual(["arcade:score"]);
  });

  it("prefixes localStorage keys", async () => {
    const storage = fakeLocalStorage();
    await createLocalStorageStore(storage).set("score", 1);
    expect([...storage.data.keys()]).toEqual(["arcade:score"]);
  });
});

describe("localStorage backend", () => {
  it("falls back instead of throwing when a saved entry is corrupt", async () => {
    const storage = fakeLocalStorage();
    storage.setItem("arcade:score", "{not json");
    expect(await createLocalStorageStore(storage).get("score", 7)).toBe(7);
  });
});
