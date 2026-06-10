/**
 * Test Configuration and Helpers
 * Shared utilities for API tests
 */

import axios from 'axios';

export const TEST_CONFIG = {
  API_URL: process.env.API_URL || 'http://localhost:3001',
  MOCK_TOKENS: {
    admin: 'token_admin_abc123',
    analyst: 'token_analyst_xyz789',
    support: 'token_support_def456',
  },
  TIMEOUT: 10000,
};

/**
 * Create an axios instance with auth header
 */
export function createAuthClient(token: string) {
  return axios.create({
    baseURL: TEST_CONFIG.API_URL,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    timeout: TEST_CONFIG.TIMEOUT,
  });
}

/**
 * Wait for service to be healthy
 */
export async function waitForHealthy(maxAttempts = 5) {
  let lastError: any;
  
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      const response = await axios.get(`${TEST_CONFIG.API_URL}/health`, {
        timeout: 2000,
      });
      
      if (response.data.status === 'healthy') {
        return true;
      }
    } catch (error) {
      lastError = error;
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }
  
  throw new Error(`Service did not become healthy after ${maxAttempts} attempts: ${lastError?.message}`);
}

/**
 * Assert correlation ID is present
 */
export function assertCorrelationId(headers: Record<string, any>) {
  const correlationId = headers['x-correlation-id'];
  if (!correlationId) {
    throw new Error('Missing X-Correlation-ID header');
  }
  return correlationId;
}
