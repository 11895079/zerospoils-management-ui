/**
 * Unit Tests for API Middleware
 * Tests authentication, authorization, correlation ID, and logging
 */

import { Request, Response, NextFunction } from 'express';
import {
  correlationIdMiddleware,
  authMiddleware,
  requireRole,
} from '../../middleware/auth';

describe('Middleware - Correlation ID', () => {
  it('should generate correlation ID if not present', () => {
    const req = { headers: {} } as Request;
    const res = {} as Response;
    const next = jest.fn();

    correlationIdMiddleware(req, res, next);

    expect(req.correlationId).toBeDefined();
    expect(typeof req.correlationId).toBe('string');
    expect(req.correlationId.length).toBeGreaterThan(0);
    expect(next).toHaveBeenCalled();
  });

  it('should preserve existing correlation ID from header', () => {
    const existingId = 'test-correlation-id-12345';
    const req = { headers: { 'x-correlation-id': existingId } } as any as Request;
    const res = {} as Response;
    const next = jest.fn();

    correlationIdMiddleware(req, res, next);

    expect(req.correlationId).toBe(existingId);
    expect(next).toHaveBeenCalled();
  });
});

describe('Middleware - Authentication', () => {
  it('should reject request without authorization header', () => {
    const req = {
      headers: {},
      method: 'GET',
      path: '/api/metrics',
      correlationId: 'test-123',
    } as any as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as any as Response;
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: 'Unauthorized',
      })
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('should reject request with invalid token', () => {
    const req = {
      headers: { authorization: 'Bearer invalid-token-xyz' },
      method: 'GET',
      path: '/api/metrics',
      correlationId: 'test-123',
    } as any as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as any as Response;
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('should accept valid admin token', () => {
    const req = {
      headers: { authorization: 'Bearer token_admin_abc123' },
      method: 'GET',
      path: '/api/metrics',
      correlationId: 'test-123',
    } as any as Request;
    const res = {} as Response;
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(req.user).toEqual({
      email: 'admin@zerospoils.local',
      role: 'admin',
    });
    expect(next).toHaveBeenCalled();
  });

  it('should accept valid analyst token', () => {
    const req = {
      headers: { authorization: 'Bearer token_analyst_xyz789' },
      method: 'GET',
      path: '/api/metrics',
      correlationId: 'test-123',
    } as any as Request;
    const res = {} as Response;
    const next = jest.fn();

    authMiddleware(req, res, next);

    expect(req.user).toEqual({
      email: 'analyst@zerospoils.local',
      role: 'analyst',
    });
    expect(next).toHaveBeenCalled();
  });

  it('should not leak token values in error responses', () => {
    const req = {
      headers: { authorization: 'Bearer invalid-token' },
      method: 'GET',
      path: '/api/metrics',
      correlationId: 'test-123',
    } as any as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as any as Response;
    const next = jest.fn();

    authMiddleware(req, res, next);

    const responseBody = JSON.stringify(res.json.mock.calls[0][0]);
    expect(responseBody).not.toContain('token_');
    expect(responseBody).not.toContain('token_admin');
    expect(responseBody).not.toContain('token_analyst');
  });
});

describe('Middleware - Role-Based Access Control', () => {
  it('admin role should access restricted endpoint', () => {
    const req = {
      user: { email: 'admin@zerospoils.local', role: 'admin' },
      headers: {},
      correlationId: 'test-123',
    } as any as Request;
    const res = {} as Response;
    const next = jest.fn();

    const roleMiddleware = requireRole('admin', 'analyst');
    roleMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
  });

  it('analyst role should access analyst-restricted endpoint', () => {
    const req = {
      user: { email: 'analyst@zerospoils.local', role: 'analyst' },
      headers: {},
      correlationId: 'test-123',
    } as any as Request;
    const res = {} as Response;
    const next = jest.fn();

    const roleMiddleware = requireRole('analyst', 'admin');
    roleMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
  });

  it('support role should be rejected from admin-only endpoint', () => {
    const req = {
      user: { email: 'support@zerospoils.local', role: 'support' },
      headers: {},
      correlationId: 'test-123',
    } as any as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as any as Response;
    const next = jest.fn();

    const roleMiddleware = requireRole('admin', 'analyst');
    roleMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });

  it('should not execute next if user role missing', () => {
    const req = {
      user: { email: 'test@example.com' }, // no role field
      headers: {},
      correlationId: 'test-123',
    } as any as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as any as Response;
    const next = jest.fn();

    const roleMiddleware = requireRole('admin');
    roleMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });
});
