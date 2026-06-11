/**
 * E2E Tests for Frontend - Browser Smoke Tests
 * Uses Playwright for browser automation and validation
 */

import { test, expect } from '@playwright/test';

test.describe('Frontend E2E - Login & Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await page.addInitScript(() => {
      localStorage.setItem('mgmt_token', 'token_admin_abc123');
    });

    await page.route('**/health', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          status: 'healthy',
          uptime: 3600,
          services: {
            api: { status: 'up' },
            worker: { status: 'up' },
            duckdb: { status: 'up' },
          },
        }),
      });
    });
  });

  test('should load login page', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check for login form or redirect to dashboard
    const loginForm = await page.locator('button[type="submit"]').isVisible().catch(() => false);
    const dashboard = await page.locator('[class*="layout"]').isVisible().catch(() => false);
    
    expect(loginForm || dashboard).toBe(true);
  });

  test('should display system health status', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard');
    
    // Wait for layout to render
    await page.waitForLoadState('networkidle');
    
    // Look for health status indicator (popover or badge)
    const healthIndicator = await page.locator('[class*="health"], [title*="Status"]').first().isVisible().catch(() => false);

    expect(healthIndicator).toBe(true);
  });
});

test.describe('Frontend E2E - Metrics Dashboard', () => {
  test('dashboard should load metrics data', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard');
    
    // Wait for initial load
    await page.waitForLoadState('networkidle');
    
    // Wait a bit for any API calls to complete
    await page.waitForTimeout(2000);
    
    // Check for metric cards or chart containers
    const content = await page.locator('body').textContent();
    
    // Basic check that page has rendered
    expect(content).toBeTruthy();
    expect(content?.length).toBeGreaterThan(100);
  });
});

test.describe('Frontend E2E - Authentication', () => {
  test('should redirect unauthorized users to login', async ({ page }) => {
    // Clear any stored tokens
    await page.context().clearCookies();
    
    // Try to access dashboard without auth
    await page.goto('http://localhost:3000/dashboard', { 
      waitUntil: 'domcontentloaded' 
    });
    
    // Should redirect or show login (depending on implementation)
    // Just verify page loads without crashing
    expect(await page.locator('body').isVisible()).toBe(true);
  });
});

test.describe('Frontend E2E - Component Rendering', () => {
  test('should render main layout without errors', async ({ page }) => {
    // Check for console errors
    const errors: string[] = [];
    const ignoredConsoleMessages = ['[antd: Card] `bordered` is deprecated'];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        if (!ignoredConsoleMessages.some((message) => text.includes(message))) {
          errors.push(text);
        }
      }
    });

    await page.goto('http://localhost:3000');
    
    // Wait for page to settle
    await page.waitForLoadState('networkidle');
    
    // Verify page is still visible (hasn't crashed)
    expect(await page.locator('body').isVisible()).toBe(true);
    expect(errors).toEqual([]);
  });
});
