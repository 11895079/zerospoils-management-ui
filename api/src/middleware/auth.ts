import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { MOCK_AUTH_TOKENS, MOCK_USERS } from '../mocks/data.js';
import type { AuthUser } from '../types/index.js';

// Extend Express Request to include auth context
declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
      correlationId: string;
    }
  }
}

/**
 * Correlation ID middleware - adds request tracing
 */
export function correlationIdMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  req.correlationId =
    (req.headers['x-correlation-id'] as string) || uuidv4();
  res.setHeader('x-correlation-id', req.correlationId);
  next();
}

/**
 * Mock authentication middleware
 * Checks Authorization header for mock tokens
 * In production, this would validate JWTs against Supabase Auth
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  // For demo purposes, allow some routes without auth
  if (req.path === '/health' || req.path === '/status') {
    return next();
  }

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing or invalid Authorization header',
      hint: 'Use: Authorization: Bearer <token>',
    });
    return;
  }

  const token = authHeader.slice(7); // Remove "Bearer " prefix

  // Look up user by token
  let user: AuthUser | undefined;
  for (const [email, tokenValue] of Object.entries(MOCK_AUTH_TOKENS)) {
    if (tokenValue === token) {
      const mockUser = Object.values(MOCK_USERS).find((u) => u.email === email);
      if (mockUser) {
        user = mockUser;
        break;
      }
    }
  }

  if (!user) {
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid token',
      hint: 'Use a valid token from your authenticated session.',
    });
    return;
  }

  req.user = user;
  next();
}

/**
 * Role-based authorization middleware
 * Ensures user has one of the required roles
 */
export function requireRole(...allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        error: 'Forbidden',
        message: `This endpoint requires one of: ${allowedRoles.join(', ')}`,
      });
      return;
    }

    next();
  };
}

/**
 * Request logging middleware
 */
export function requestLoggingMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const startTime = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const correlationId = req.correlationId;
    const user = req.user?.email || 'unauthenticated';

    console.log(
      `[${correlationId}] ${req.method} ${req.path} - ${res.statusCode} (${duration}ms) - ${user}`
    );
  });

  next();
}
