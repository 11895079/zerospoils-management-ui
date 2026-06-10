/**
 * Integration Tests for Management API
 * Tests API contract and RBAC behavior
 */

import axios from 'axios';
import {
  TEST_CONFIG,
  createAuthClient,
  assertCorrelationId,
} from './helpers';

describe('Management API - Integration Tests', () => {
  beforeAll(async () => {
    // Optionally wait for service to be ready
    // await waitForHealthy();
  });

  describe('RBAC Authorization', () => {
    it('admin role should access metrics endpoints', async () => {
      const client = createAuthClient(TEST_CONFIG.MOCK_TOKENS.admin);
      const response = await client.get('/api/metrics/current');
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('data');
    });

    it('analyst role should access metrics endpoints', async () => {
      const client = createAuthClient(TEST_CONFIG.MOCK_TOKENS.analyst);
      const response = await client.get('/api/metrics/current');
      expect(response.status).toBe(200);
    });

    it('invalid token should be rejected', async () => {
      const client = createAuthClient('invalid-token-12345');
      try {
        await client.get('/api/metrics/current');
        fail('Should have thrown 401 error');
      } catch (error: any) {
        expect(error.response?.status).toBe(401);
      }
    });
  });

  describe('Error Responses', () => {
    it('404 should not leak sensitive information', async () => {
      try {
        const client = createAuthClient(TEST_CONFIG.MOCK_TOKENS.admin);
        await client.get('/api/nonexistent-endpoint');
        fail('Should have thrown 404 error');
      } catch (error: any) {
        expect(error.response?.status).toBe(404);
        const body = error.response?.data;
        // Verify no token hints in error response
        expect(body).not.toContain('token_');
        expect(body).not.toContain('Bearer ');
      }
    });

    it('401 should not leak valid tokens', async () => {
      try {
        const client = axios.create({
          baseURL: TEST_CONFIG.API_URL,
          timeout: TEST_CONFIG.TIMEOUT,
        });
        await client.get('/api/metrics/current');
        fail('Should have thrown 401 error');
      } catch (error: any) {
        expect(error.response?.status).toBe(401);
        const body = error.response?.data;
        // Verify no token values in error response
        expect(JSON.stringify(body)).not.toContain('token_admin');
        expect(JSON.stringify(body)).not.toContain('token_analyst');
      }
    });
  });

  describe('Request Tracing', () => {
    it('all responses should include correlation ID', async () => {
      const client = createAuthClient(TEST_CONFIG.MOCK_TOKENS.admin);
      
      const endpoints = [
        '/api/metrics/current',
        '/api/metrics/summary',
        '/api/feedback',
      ];
      
      for (const endpoint of endpoints) {
        try {
          const response = await client.get(endpoint);
          const correlationId = assertCorrelationId(response.headers);
          expect(correlationId).toMatch(/^[a-f0-9\-]+$/i); // UUID or similar
        } catch (error: any) {
          // Some endpoints might fail but should still have correlation ID
          const correlationId = assertCorrelationId(error.response?.headers || {});
          expect(correlationId).toBeDefined();
        }
      }
    });
  });

  describe('Service Configuration', () => {
    it('status endpoint should report profile and version', async () => {
      const response = await axios.get(`${TEST_CONFIG.API_URL}/status`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('profile');
      expect(response.data.profile).toMatch(/^(local|staging|cloud)$/);
      expect(response.data).toHaveProperty('version');
    });
  });
});
