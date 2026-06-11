/**
 * Smoke Tests for Management Frontend
 * Validates core component rendering and integration
 */

import { describe, it, expect, vi } from 'vitest';
import { render } from '@testing-library/react';

const mockLocalStorage = () => {
  const storage: Record<string, string> = {};
  vi.stubGlobal('localStorage', {
    getItem: vi.fn((key: string) => storage[key] ?? null),
    setItem: vi.fn((key: string, value: string) => {
      storage[key] = value;
    }),
    removeItem: vi.fn((key: string) => {
      delete storage[key];
    }),
    clear: vi.fn(() => {
      Object.keys(storage).forEach((key) => delete storage[key]);
    }),
  });
};

const renderApp = async () => {
  mockLocalStorage();
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
  const { default: App } = await import('../App');
  render(<App />);
};

describe('Frontend - Smoke Tests', () => {
  it('should render App component without crashing', async () => {
    await renderApp();
    
    // App should render - check for main layout presence
    expect(document.body).toBeTruthy();
  });

  it('should have required layout structure', async () => {
    await renderApp();

    // App may render either the protected layout or login page depending on auth state.
    const contentArea = document.querySelector('[class*="layout"]');
    const loginForm = document.querySelector('form');
    expect(Boolean(contentArea || loginForm)).toBe(true);
  });
});
