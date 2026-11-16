import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import type { Plugin } from "vite";
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

const root = import.meta.dirname;
const pkg = JSON.parse(readFileSync(resolve(root, "package.json"), "utf8")) as {
  version: string;
};

/**
 * package.json is the single place the version number lives.
 * After each build this copies it into the extension manifest in dist/,
 * so the web app, the extension and the macOS app can never disagree.
 */
function stampManifestVersion(): Plugin {
  return {
    name: "safari-arcade:stamp-manifest-version",
    apply: "build",
    closeBundle() {
      const manifestPath = resolve(root, "dist", "manifest.json");
      const manifest = JSON.parse(readFileSync(manifestPath, "utf8")) as Record<string, unknown>;
      manifest.version = pkg.version;
      writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
    },
  };
}

export default defineConfig({
  // Extension pages are served from safari-web-extension://<id>/, so every
  // asset path has to be relative rather than starting with "/".
  base: "./",
  // Everything in safari-extension/ (manifest, background script, icons) is
  // copied as-is into dist/, next to the built React app. dist/ is then the
  // complete web extension that Xcode wraps.
  publicDir: "safari-extension",
  plugins: [react(), stampManifestVersion()],
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    target: "safari16",
    sourcemap: false,
  },
  test: {
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
