import axios from 'axios';
import type { AxiosInstance } from 'axios';
import type { RemoteConfigCondition, RemoteConfigParameterDef } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

class ApiClient {
  private client: AxiosInstance;
  private token: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Load token from localStorage
    const savedToken = localStorage.getItem('mgmt_token');
    if (savedToken) {
      this.setToken(savedToken);
    }

    // Add correlation ID to all requests
    this.client.interceptors.request.use((config) => {
      config.headers['X-Correlation-ID'] =
        localStorage.getItem('correlation_id') || this.generateId();
      return config;
    });
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  setToken(token: string): void {
    this.token = token;
    this.client.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    localStorage.setItem('mgmt_token', token);
  }

  clearToken(): void {
    this.token = null;
    delete this.client.defaults.headers.common['Authorization'];
    localStorage.removeItem('mgmt_token');
  }

  getToken(): string | null {
    return this.token;
  }

  // Health & Status
  async getHealth() {
    return this.client.get('/health');
  }

  async getStatus() {
    return this.client.get('/status');
  }

  // Metrics
  async getCurrentMetrics() {
    return this.client.get('/api/metrics/current');
  }

  async getMetricsHistory(hours: number = 24) {
    return this.client.get('/api/metrics/history', { params: { hours } });
  }

  async getMetricsSummary() {
    return this.client.get('/api/metrics/summary');
  }

  // Feedback
  async getFeedback(status?: string, severity?: string) {
    return this.client.get('/api/feedback', {
      params: { status, severity },
    });
  }

  async getFeedbackItem(id: string) {
    return this.client.get(`/api/feedback/${id}`);
  }

  async triageFeedback(id: string, note: string) {
    return this.client.post(`/api/feedback/${id}/triage`, { note });
  }

  async getFeedbackStats() {
    return this.client.get('/api/feedback/stats/summary');
  }

  // Telemetry
  async getTelemetryEvents(
    platform?: string,
    eventName?: string,
    limit?: number
  ) {
    return this.client.get('/api/telemetry/events', {
      params: { platform, event: eventName, limit },
    });
  }

  async getTelemetrySummary() {
    return this.client.get('/api/telemetry/summary');
  }

  async getTelemetryPlatforms() {
    return this.client.get('/api/telemetry/platforms');
  }

  // Remote Config
  async getRemoteConfigTemplate() {
    return this.client.get('/api/remote-config/template');
  }

  async getRemoteConfigHistory(limit: number = 20) {
    return this.client.get('/api/remote-config/history', {
      params: { limit },
    });
  }

  async validateRemoteConfig(payload: {
    parameters: Record<string, RemoteConfigParameterDef>;
    etag: string;
  }) {
    return this.client.post('/api/remote-config/validate', payload);
  }

  async publishRemoteConfig(payload: {
    parameters: Record<string, RemoteConfigParameterDef>;
    conditions?: RemoteConfigCondition[];
    etag: string;
  }) {
    return this.client.put('/api/remote-config/publish', payload);
  }
}

export const api = new ApiClient();
