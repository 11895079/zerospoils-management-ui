/**
 * Telemetry Analytics Routes
 *
 * Provides detailed analytics endpoints for:
 * - Camera adoption and quality metrics
 * - Waste analysis by category
 * - Entry source distribution
 * - Retention cohort analysis
 */

import { Router, Request, Response } from 'express';
import fetch from 'node-fetch';
import { requireRole } from '../middleware/auth.js';

const router = Router();
const WORKER_URL = process.env.WORKER_URL || 'http://worker:3002';

/**
 * Camera Adoption Analytics
 * Shows how users are using camera for item entry
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/camera-adoption',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      const response = await fetch(`${WORKER_URL}/metrics/camera-adoption`);

      if (!response.ok) {
        return res.status(503).json({
          error: 'Worker service unavailable',
        });
      }

      const result = (await response.json()) as any;

      res.json({
        data: result.data || [],
        metadata: {
          description: 'Camera adoption rates by entry source',
          metrics: ['camera_adoption_pct', 'barcode_accepted_pct', 'expiry_accepted_pct'],
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * Waste Analysis by Category
 * Shows which categories waste the most and why
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/waste-analysis',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      const response = await fetch(`${WORKER_URL}/metrics/waste-analysis`);

      if (!response.ok) {
        return res.status(503).json({
          error: 'Worker service unavailable',
        });
      }

      const result = (await response.json()) as any;

      // Transform data for API response
      const data = (result.data || []).map((row: any) => ({
        category: row.category_name,
        totalWasted: row.total_wasted,
        totalCost: row.total_cost_usd,
        avgDaysInInventory: row.avg_days_in_inventory,
      }));

      res.json({
        data,
        metadata: {
          description: 'Waste analysis by category (cost impact)',
          period: 'Last 30 days',
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * Entry Source Distribution
 * Shows how items are being added (manual vs camera vs other)
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/entry-sources',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      // Fetch camera adoption data which includes entry source breakdown
      const response = await fetch(`${WORKER_URL}/metrics/camera-adoption`);

      if (!response.ok) {
        return res.status(503).json({
          error: 'Worker service unavailable',
        });
      }

      const result = (await response.json()) as any;
      const data = result.data || [];

      // Calculate totals by entry source
      const sourceStats = data.reduce(
        (acc: any, row: any) => {
          const source = row.source_name || 'unknown';
          if (!acc[source]) {
            acc[source] = {
              count: 0,
              avgBarcodeConfidence: 0,
              avgExpiryConfidence: 0,
            };
          }
          acc[source].count += row.item_count || 0;
          acc[source].avgBarcodeConfidence += (row.avg_barcode_confidence || 0) * (row.item_count || 1);
          acc[source].avgExpiryConfidence += (row.avg_expiry_confidence || 0) * (row.item_count || 1);
          return acc;
        },
        {}
      );

      // Normalize averages
      const normalized = Object.entries(sourceStats).map(([source, stats]: any) => ({
        source,
        count: stats.count,
        percentage: 0, // Will be calculated below
        avgBarcodeConfidence: stats.count > 0 ? stats.avgBarcodeConfidence / stats.count : 0,
        avgExpiryConfidence: stats.count > 0 ? stats.avgExpiryConfidence / stats.count : 0,
      }));

      // Calculate percentages
      const total = normalized.reduce((sum, s) => sum + s.count, 0);
      normalized.forEach((s) => {
        s.percentage = total > 0 ? (s.count / total) * 100 : 0;
      });

      res.json({
        data: normalized,
        metadata: {
          description: 'Item entry method distribution and quality metrics',
          total_items: total,
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * Retention Cohort Analysis
 * Shows user retention by install cohort
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/retention-cohorts',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      const response = await fetch(`${WORKER_URL}/etl/history?limit=100`);

      if (!response.ok) {
        return res.status(503).json({
          error: 'Worker service unavailable',
        });
      }

      // For now, return mock retention data
      // In production, would query retention cohort mart from DuckDB
      const data = [
        {
          install_date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
            .toISOString()
            .split('T')[0],
          d0_retention: 1.0,
          d1_retention: 0.75,
          d7_retention: 0.45,
          d30_retention: 0.25,
        },
        {
          install_date: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000)
            .toISOString()
            .split('T')[0],
          d0_retention: 1.0,
          d1_retention: 0.72,
          d7_retention: 0.42,
          d30_retention: null,
        },
        {
          install_date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000)
            .toISOString()
            .split('T')[0],
          d0_retention: 1.0,
          d1_retention: 0.78,
          d7_retention: null,
          d30_retention: null,
        },
      ];

      res.json({
        data,
        metadata: {
          description: 'User retention by install cohort (D0, D1, D7, D30)',
          note: 'Null values indicate not yet measured',
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * Category Performance
 * Shows engagement and waste metrics by grocery category
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/categories',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      // Mock category data - would be from DuckDB in production
      const categories = [
        {
          name: 'Dairy',
          itemsAdded: 2450,
          itemsWasted: 340,
          wasteRate: 13.9,
          avgDaysInStorage: 8,
          totalWasteCost: 1250,
        },
        {
          name: 'Produce',
          itemsAdded: 3120,
          itemsWasted: 680,
          wasteRate: 21.8,
          avgDaysInStorage: 6,
          totalWasteCost: 2100,
        },
        {
          name: 'Meat',
          itemsAdded: 1250,
          itemsWasted: 85,
          wasteRate: 6.8,
          avgDaysInStorage: 3,
          totalWasteCost: 890,
        },
        {
          name: 'Pantry',
          itemsAdded: 4560,
          itemsWasted: 180,
          wasteRate: 3.9,
          avgDaysInStorage: 45,
          totalWasteCost: 320,
        },
      ];

      res.json({
        data: categories,
        metadata: {
          description: 'Engagement and waste metrics by category',
          period: 'Last 30 days',
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * Barcode Quality Analysis
 * Shows barcode recognition quality from different sources
 * Available to: analyst, admin
 */
router.get(
  '/telemetry/barcode-quality',
  requireRole('admin', 'analyst'),
  async (req: Request, res: Response) => {
    try {
      // Mock data - would be from DuckDB barcode quality mart in production
      const data = [
        {
          source: 'Seed Catalog',
          itemCount: 4500,
          avgBarcodeConfidence: 0.96,
          avgExpiryConfidence: 0.89,
          itemsWithExpiry: 3800,
        },
        {
          source: 'Learned Mapping',
          itemCount: 1200,
          avgBarcodeConfidence: 0.82,
          avgExpiryConfidence: 0.71,
          itemsWithExpiry: 600,
        },
        {
          source: 'Manual Entry',
          itemCount: 2350,
          avgBarcodeConfidence: null,
          avgExpiryConfidence: null,
          itemsWithExpiry: 890,
        },
      ];

      res.json({
        data,
        metadata: {
          description: 'Barcode and expiry recognition accuracy by source',
          note: 'Manual entries have no confidence scores',
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: String(error),
      });
    }
  }
);

/**
 * ETL Pipeline Status
 * Shows when telemetry data was last processed
 * Available to: admin
 */
router.get('/telemetry/etl-status', requireRole('admin'), async (req: Request, res: Response) => {
  try {
    const response = await fetch(`${WORKER_URL}/etl/history?limit=5`);

    if (!response.ok) {
      return res.status(503).json({
        error: 'Worker service unavailable',
      });
    }

    const result = (await response.json()) as any;
    const runs = (result.data || []).slice(0, 5);

    res.json({
      last_run: runs[0] || null,
      recent_runs: runs,
      metadata: {
        description: 'ETL pipeline execution history',
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      error: String(error),
    });
  }
});

export default router;
