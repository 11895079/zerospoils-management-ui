import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import {
  correlationIdMiddleware,
  authMiddleware,
  requestLoggingMiddleware,
} from './middleware/auth.js';
import healthRoutes from './routes/health.js';
import metricsRoutes from './routes/metrics.js';
import feedbackRoutes from './routes/feedback.js';
import telemetryRoutes from './routes/telemetry.js';

// Load environment variables
dotenv.config();

const app = express();
const port = parseInt(process.env.API_PORT || '3001');
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:3000';

// Middleware
app.use(express.json());
app.use(cors({ origin: corsOrigin }));
app.use(correlationIdMiddleware);
app.use(requestLoggingMiddleware);

// Health check (no auth required)
app.use(healthRoutes);

// Auth middleware for all other routes
app.use(authMiddleware);

// API Routes
app.use('/api', metricsRoutes);
app.use('/api', feedbackRoutes);
app.use('/api', telemetryRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `${req.method} ${req.path} not found`,
    hint: 'Available endpoints: /health, /status, /api/metrics/*, /api/feedback/*, /api/telemetry/*',
  });
});

// Error handler
app.use(
  (
    err: Error,
    req: express.Request,
    res: express.Response,
    _next: express.NextFunction
  ) => {
    console.error(`[${req.correlationId}] Error:`, err.message);

    res.status(500).json({
      error: 'Internal Server Error',
      message: err.message,
      correlationId: req.correlationId,
    });
  }
);

// Start server
app.listen(port, () => {
  console.log(`\n🚀 Management API running on http://localhost:${port}`);
  console.log(`📝 Profile: ${process.env.APP_PROFILE || 'local'}`);
  console.log(`🔐 CORS Origin: ${corsOrigin}`);
  console.log(`\n📚 Available endpoints:`);
  console.log(`  GET  /health           - Service health check`);
  console.log(`  GET  /status           - Service status & config`);
  console.log(`\n  Auth required (Bearer token):`);
  console.log(`  GET  /api/metrics/current`);
  console.log(`  GET  /api/metrics/history`);
  console.log(`  GET  /api/metrics/summary`);
  console.log(`  GET  /api/feedback`);
  console.log(`  POST /api/feedback/:id/triage`);
  console.log(`  GET  /api/telemetry/events`);
  console.log(`  GET  /api/telemetry/summary`);
  console.log(`\n🔑 Mock tokens for testing:`);
  console.log(`  admin:    Bearer token_admin_abc123`);
  console.log(`  analyst:  Bearer token_analyst_xyz789`);
  console.log(`  support:  Bearer token_support_def456`);
  console.log(`\n💡 Test with: curl -H "Authorization: Bearer token_admin_abc123" http://localhost:${port}/api/metrics/current\n`);
});

export default app;
