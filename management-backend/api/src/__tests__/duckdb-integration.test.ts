/**
 * DuckDB Integration Tests
 *
 * Tests for API integration with DuckDB metrics via worker service
 */

import {
  getCurrentMetrics,
  getHistoricalMetrics,
  isDuckDBReady,
  CurrentMetrics,
} from '../services/duckdb';

// Mock node-fetch
jest.mock('node-fetch');
import fetch from 'node-fetch';

const mockFetch = fetch as jest.MockedFunction<typeof fetch>;

describe('DuckDB Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getCurrentMetrics', () => {
    it('should transform DuckDB response to API format', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: {
            new_installs_24h: 150,
            reinstalls_24h: 30,
            active_users_24h: 2500,
            items_added_24h: 12000,
            items_wasted_24h: 800,
            total_waste_cost_cents_24h: 45000,
            camera_assist_items_pct: 65.5,
            d1_retention_pct: 75.0,
            crash_free_rate_pct: 99.8,
            avg_session_duration_seconds: 245,
            notification_opt_in_rate_pct: 82.3,
            summary_timestamp: '2026-06-10T12:00:00Z',
          },
        }),
      } as any);

      const metrics = await getCurrentMetrics();

      expect(metrics).toEqual({
        newInstalls: 150,
        reinstalls: 30,
        activeUsers: 2500,
        itemsAdded: 12000,
        itemsWasted: 800,
        totalWasteCost: 450, // Converted from cents
        camerAssistanceRate: 0.655, // Converted from percentage
        d1Retention: 0.75, // Converted from percentage
        crashFreeRate: 0.998,
        avgSessionDuration: 245,
        notificationOptInRate: 0.823,
        timestamp: '2026-06-10T12:00:00Z',
      });
    });

    it('should handle missing data fields gracefully', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: {
            new_installs_24h: 150,
            // Other fields missing
          },
        }),
      } as any);

      const metrics = await getCurrentMetrics();

      expect(metrics).not.toBeNull();
      expect(metrics?.newInstalls).toBe(150);
      expect(metrics?.activeUsers).toBe(0);
    });

    it('should return null when worker is unavailable', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 503,
      } as any);

      const metrics = await getCurrentMetrics();

      expect(metrics).toBeNull();
    });

    it('should return null when fetch fails', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      const metrics = await getCurrentMetrics();

      expect(metrics).toBeNull();
    });
  });

  describe('getHistoricalMetrics', () => {
    it('should fetch and transform historical metrics', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: [
            {
              summary_timestamp: '2026-06-09T12:00:00Z',
              new_installs_24h: 140,
              active_users_24h: 2400,
              items_added_24h: 11500,
              d1_retention_pct: 74.5,
              crash_free_rate_pct: 99.7,
            },
            {
              summary_timestamp: '2026-06-08T12:00:00Z',
              new_installs_24h: 135,
              active_users_24h: 2350,
              items_added_24h: 11000,
              d1_retention_pct: 73.8,
              crash_free_rate_pct: 99.6,
            },
          ],
        }),
      } as any);

      const metrics = await getHistoricalMetrics(7);

      expect(metrics).toHaveLength(2);
      expect(metrics[0]).toMatchObject({
        timestamp: '2026-06-09T12:00:00Z',
        newInstalls: 140,
        activeUsers: 2400,
        itemsAdded: 11500,
        d1Retention: 0.745,
        crashFreeRate: 0.997,
      });
    });

    it('should clamp days parameter', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ data: [] }),
      } as any);

      // Request with too many days
      await getHistoricalMetrics(100);

      const url = (mockFetch.mock.calls[0][0] as string);
      expect(url).toContain('days=30'); // Should be clamped to 30
    });

    it('should return empty array on error', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      const metrics = await getHistoricalMetrics(7);

      expect(metrics).toEqual([]);
    });
  });

  describe('isDuckDBReady', () => {
    it('should return true when metrics are available', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          data: {
            new_installs_24h: 100,
          },
        }),
      } as any);

      const ready = await isDuckDBReady();

      expect(ready).toBe(true);
    });

    it('should return false when metrics are unavailable', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 503,
      } as any);

      const ready = await isDuckDBReady();

      expect(ready).toBe(false);
    });
  });
});
