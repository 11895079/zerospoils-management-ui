/**
 * Remote Config API endpoints
 */

import { Router, Request, Response } from 'express';
import {
  getCurrentTemplate,
  getTemplateHistory,
  validatePublish,
  publishTemplate,
  rollbackTemplate,
  getVersionHistory,
} from '../services/remoteConfigService.js';

const router = Router();

/**
 * GET /api/remote-config/template
 * Fetch current Firebase Remote Config template
 */
router.get('/template', async (_req: Request, res: Response) => {
  try {
    const template = await getCurrentTemplate();
    return res.json({
      template,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

/**
 * GET /api/remote-config/history
 * Fetch template change audit trail
 */
router.get('/history', async (req: Request, res: Response) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
    const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(limit, 100)) : 20;
    const history = await getTemplateHistory(safeLimit);
    return res.json({
      changes: history,
      count: history.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

/**
 * GET /api/remote-config/versions
 * Get list of template versions for rollback
 */
router.get('/versions', async (req: Request, res: Response) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 50;
    const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(limit, 100)) : 50;
    const versions = await getVersionHistory(safeLimit);
    return res.json({
      versions,
      count: versions.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

/**
 * POST /api/remote-config/validate
 * Validate parameter changes before publishing
 */
router.post('/validate', async (req: Request, res: Response) => {
  try {
    const validation = await validatePublish(req.body);
    return res.json({
      valid: validation.valid,
      errors: validation.errors,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(400).json({ error: String(error) });
  }
});

/**
 * PUT /api/remote-config/publish
 * Publish template changes with etag-based conflict resolution
 */
router.put('/publish', async (req: Request, res: Response) => {
  try {
    if (!req.body?.parameters) {
      return res.status(400).json({ error: 'parameters is required' });
    }

    // In real app, would get user from auth middleware
    const user = req.headers['x-user'] || 'anonymous';
    const correlationId = req.headers['x-correlation-id'] || `corr-${Date.now()}`;

    const result = await publishTemplate(req.body, String(user));

    if (!result.success) {
      const statusCode = result.error?.code === 'ETAG_MISMATCH' ? 409 : 400;
      return res.status(statusCode).json(result);
    }

    return res.status(200).json(result);
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

/**
 * POST /api/remote-config/rollback
 * Rollback template to prior version
 */
router.post('/rollback', async (req: Request, res: Response) => {
  try {
    if (!req.body?.targetVersionNumber) {
      return res.status(400).json({ error: 'targetVersionNumber is required' });
    }

    const user = req.headers['x-user'] || 'anonymous';
    const correlationId = req.headers['x-correlation-id'] || `corr-${Date.now()}`;

    const result = await rollbackTemplate(
      req.body.targetVersionNumber,
      String(user),
      String(correlationId)
    );

    if (!result.success) {
      return res.status(400).json(result);
    }

    return res.json(result);
  } catch (error) {
    return res.status(500).json({ error: String(error) });
  }
});

export default router;
