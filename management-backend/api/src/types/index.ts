// Role-based access control
export type UserRole = 'admin' | 'analyst' | 'support';

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
}

export interface AuthContext {
  user: AuthUser | null;
  correlationId: string;
}

// Dashboard metrics
export interface MetricsSnapshot {
  timestamp: string;
  newInstalls: number;
  activeUsers: number;
  crashFreeRate: number;
  d1Retention: number;
  avgSessionLength: number;
  itemsAdded: number;
  notificationOptInRate: number;
}

export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  services: {
    api: ServiceHealth;
    worker: ServiceHealth;
    duckdb: ServiceHealth;
  };
  uptime: number; // seconds
}

export interface ServiceHealth {
  status: 'up' | 'down';
  responseTime: number; // milliseconds
  lastCheck: string;
  version: string;
}

export interface AppConfig {
  profile: 'local' | 'staging' | 'cloud';
  apiPort: number;
  workerPort: number;
  duckdbPath: string;
  redisUrl: string;
  jwtSecret: string;
  corsOrigin: string;
}

// Feedback/Triage
export interface Feedback {
  id: string;
  userId: string;
  type: 'bug' | 'feature_request' | 'general';
  title: string;
  description: string;
  severity?: 'low' | 'medium' | 'high';
  status: 'untriaged' | 'triaged' | 'resolved';
  createdAt: string;
  triageNote?: string;
  triageEmail?: string;
}

// Telemetry event
export interface TelemetryEvent {
  id: string;
  eventName: string;
  userId: string;
  platform: 'ios' | 'android';
  appVersion: string;
  timestamp: string;
  properties: Record<string, unknown>;
}
