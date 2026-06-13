import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

// Static marketing page for Investanco. Builds to dist/ for any static host.
export default defineConfig({
  // Relative base so assets resolve under the GitHub Pages project subpath
  // (/Investanco/). The live app is published one level down at /Investanco/app/.
  base: "./",
  plugins: [tailwindcss()],
  build: { outDir: "dist", emptyOutDir: true },
});
