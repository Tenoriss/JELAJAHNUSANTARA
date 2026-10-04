import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Data cerita (dialog, quest, item, catatan, peta) dipakai bersama dengan
      // versi Godot: satu sumber kebenaran, tidak ada salinan kedua.
      '@data': resolve(here, '../data'),
    },
  },
  server: {
    host: true, // 0.0.0.0 agar pratinjau di browser bisa tersambung
    port: 5173,
    strictPort: true,
    allowedHosts: true,
    fs: { allow: ['..'] }, // izinkan membaca ../data
  },
  preview: {
    host: true,
    port: 4173,
    allowedHosts: true,
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    sourcemap: false,
  },
});
