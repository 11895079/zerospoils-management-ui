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
import remoteConfigRoutes from './routes/remoteConfig.js';

// Load environment variables
dotenv.config();

// Validate required environment variables
const requiredEnvVars = ['APP_PROFILE', 'CORS_ORIGIN'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.warn(`⚠️  Environment variable ${envVar} not set, using default`);
  }
}

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
app.use('/api/remote-config', remoteConfigRoutes);

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
  console.log(`\n✅ Management API initialized`);
  console.log(`   Port: ${port}`);
  console.log(`   Profile: ${process.env.APP_PROFILE || 'local'}`);
  console.log(`   CORS Origin: ${corsOrigin}`);
  console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\n📚 Available endpoints:`);
  console.log(`   GET  /health           - Service health check`);
  console.log(`   GET  /status           - Service status & config`);
  console.log(`   GET  /api/metrics/*    - Metrics endpoints (auth required)`);
  console.log(`   GET  /api/feedback/*   - Feedback endpoints (auth required)`);
  console.log(`   GET  /api/telemetry/*  - Telemetry endpoints (auth required)\n`);
});

export default app;
