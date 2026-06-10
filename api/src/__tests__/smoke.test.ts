/**
 * Smoke Tests for Management API
 * Validates core API routes and health checks
 */

import axios from 'axios';

const API_URL = 'http://localhost:3001';
const MOCK_TOKEN = 'token_admin_abc123';

describe('Management API - Smoke Tests', () => {
  describe('Health Endpoints', () => {
    it('should respond to /health check', async () => {
      const response = await axios.get(`${API_URL}/health`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status');
      expect(response.data).toHaveProperty('timestamp');
      expect(response.data).toHaveProperty('services');
    });

    it('should respond to /status endpoint', async () => {
      const response = await axios.get(`${API_URL}/status`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('service');
      expect(response.data).toHaveProperty('profile');
      expect(response.data).toHaveProperty('version');
    });
  });

  describe('Authentication', () => {
    it('should reject request without authorization header', async () => {
      try {
        await axios.get(`${API_URL}/api/metrics/current`);
        fail('Should have thrown 401 error');
      } catch (error: any) {
        expect(error.response?.status).toBe(401);
        expect(error.response?.data).toHaveProperty('error');
      }
    });

    it('should accept request with valid Bearer token', async () => {
      const response = await axios.get(`${API_URL}/api/metrics/current`, {
        headers: {
          Authorization: `Bearer ${MOCK_TOKEN}`,
        },
      });
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('data');
    });
  });

  describe('Metrics Endpoints', () => {
    it('should return current metrics', async () => {
      const response = await axios.get(`${API_URL}/api/metrics/current`, {
        headers: { Authorization: `Bearer ${MOCK_TOKEN}` },
      });
      expect(response.status).toBe(200);
      expect(response.data.data).toHaveProperty('newInstalls');
      expect(response.data.data).toHaveProperty('activeUsers');
      expect(response.data.data).toHaveProperty('crashFreeRate');
    });

    it('should return metrics history', async () => {
      const response = await axios.get(`${API_URL}/api/metrics/history?hours=24`, {
        headers: { Authorization: `Bearer ${MOCK_TOKEN}` },
      });
      expect(response.status).toBe(200);
      expect(Array.isArray(response.data.data)).toBe(true);
      expect(response.data.count).toBeGreaterThan(0);
    });
  });

  describe('Correlation IDs', () => {
    it('should include correlation ID in response headers', async () => {
      const response = await axios.get(`${API_URL}/health`);
      expect(response.headers['x-correlation-id']).toBeDefined();
      expect(typeof response.headers['x-correlation-id']).toBe('string');
    });
  });
});
