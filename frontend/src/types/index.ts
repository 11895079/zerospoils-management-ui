// API Response types
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
  uptime: number;
}

export interface ServiceHealth {
  status: 'up' | 'down';
  responseTime: number;
  lastCheck: string;
  version: string;
}

// Remote Config types
export interface RemoteConfigValue {
  value: string;
}

export interface RemoteConfigParameterDef {
  defaultValue: RemoteConfigValue;
  conditionalValues?: Record<string, RemoteConfigValue>;
  description?: string;
  valueType?: 'STRING' | 'BOOLEAN' | 'NUMBER' | 'JSON';
}

export interface RemoteConfigCondition {
  name: string;
  expression: string;
  tagColor?: string;
}

export interface RemoteConfigVersion {
  versionNumber: string;
  updateUser: string;
  updateTime: string;
}

export interface RemoteConfigTemplate {
  etag: string;
  parameters: Record<string, RemoteConfigParameterDef>;
  conditions?: RemoteConfigCondition[];
  version?: RemoteConfigVersion;
}

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

export interface TelemetryEvent {
  id: string;
  eventName: string;
  userId: string;
  platform: 'ios' | 'android';
  appVersion: string;
  timestamp: string;
  properties: Record<string, unknown>;
}

export interface AuthToken {
  token: string;
  user: {
    email: string;
    role: 'admin' | 'analyst' | 'support';
  };
}
