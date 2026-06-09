import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { mockDataStore } from '../mocks/data.js';
import { requireRole } from '../middleware/auth.js';
import type { Feedback } from '../types/index.js';

const router = Router();

/**
 * Get all feedback items
 * Available to: support, analyst, admin
 */
router.get(
  '/feedback',
  requireRole('admin', 'analyst', 'support'),
  (req: Request, res: Response) => {
    const status = req.query.status as string | undefined;
    const severity = req.query.severity as string | undefined;

    let feedback = mockDataStore.feedback;

    if (status) {
      feedback = feedback.filter((f) => f.status === status);
    }
    if (severity) {
      feedback = feedback.filter((f) => f.severity === severity);
    }

    res.json({
      data: feedback,
      count: feedback.length,
      untriaged: feedback.filter((f) => f.status === 'untriaged').length,
      timestamp: new Date().toISOString(),
    });
  }
);

/**
 * Get feedback item by ID
 * Available to: support, analyst, admin
 */
router.get(
  '/feedback/:id',
  requireRole('admin', 'analyst', 'support'),
  (req: Request, res: Response) => {
    const { id } = req.params;
    const feedback = mockDataStore.feedback.find((f) => f.id === id);

    if (!feedback) {
      res.status(404).json({ error: 'Feedback not found' });
      return;
    }

    res.json({ data: feedback });
  }
);

/**
 * Triage feedback item (mark as triaged with note)
 * Available to: support, analyst, admin
 */
router.post(
  '/feedback/:id/triage',
  requireRole('admin', 'analyst', 'support'),
  (req: Request, res: Response) => {
    const { id } = req.params;
    const { note } = req.body;

    if (!note || typeof note !== 'string') {
      res.status(400).json({ error: 'Triage note is required' });
      return;
    }

    const feedback = mockDataStore.feedback.find((f) => f.id === id);
    if (!feedback) {
      res.status(404).json({ error: 'Feedback not found' });
      return;
    }

    mockDataStore.triageFeedback(id, note, req.user!.email);

    res.json({
      message: 'Feedback triaged successfully',
      data: feedback,
      correlationId: req.correlationId,
    });
  }
);

/**
 * Create new feedback (internal)
 * Available to: admin
 */
router.post(
  '/feedback',
  requireRole('admin'),
  (req: Request, res: Response) => {
    const { type, title, description, severity, userId } = req.body;

    if (!title || !description || !type) {
      res.status(400).json({
        error: 'Missing required fields: title, description, type',
      });
      return;
    }

    const newFeedback: Feedback = {
      id: uuidv4(),
      userId: userId || req.user!.id,
      type,
      title,
      description,
      severity: severity || 'low',
      status: 'untriaged',
      createdAt: new Date().toISOString(),
    };

    mockDataStore.addFeedback(newFeedback);

    res.status(201).json({
      message: 'Feedback created successfully',
      data: newFeedback,
    });
  }
);

/**
 * Get feedback stats
 * Available to: analyst, admin
 */
router.get(
  '/feedback/stats/summary',
  requireRole('admin', 'analyst'),
  (req: Request, res: Response) => {
    const feedback = mockDataStore.feedback;

    res.json({
      total: feedback.length,
      byStatus: {
        untriaged: feedback.filter((f) => f.status === 'untriaged').length,
        triaged: feedback.filter((f) => f.status === 'triaged').length,
        resolved: feedback.filter((f) => f.status === 'resolved').length,
      },
      bySeverity: {
        low: feedback.filter((f) => f.severity === 'low').length,
        medium: feedback.filter((f) => f.severity === 'medium').length,
        high: feedback.filter((f) => f.severity === 'high').length,
      },
      byType: {
        bug: feedback.filter((f) => f.type === 'bug').length,
        feature_request: feedback.filter((f) => f.type === 'feature_request')
          .length,
        general: feedback.filter((f) => f.type === 'general').length,
      },
      timestamp: new Date().toISOString(),
    });
  }
);

export default router;
