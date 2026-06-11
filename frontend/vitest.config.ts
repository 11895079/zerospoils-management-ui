import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: [],
    include: ['src/**/*.test.{ts,tsx}', 'src/**/*.smoke.test.{ts,tsx}'],
    exclude: ['node_modules', 'dist', 'src/**/e2e.spec.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'text-summary', 'html', 'lcov', 'json'],
      exclude: [
        'node_modules/',
        'src/__tests__/',
      ],
      lines: 50,
      functions: 50,
      branches: 50,
      statements: 50,
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
