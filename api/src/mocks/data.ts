import { v4 as uuidv4 } from 'uuid';
import type { MetricsSnapshot, Feedback, TelemetryEvent } from '../types/index.js';

// Mock authenticated users
export const MOCK_USERS = {
  admin: {
    id: 'user-admin-001',
    email: 'admin@zerospoils.local',
    name: 'Admin User',
    role: 'admin' as const,
  },
  analyst: {
    id: 'user-analyst-001',
    email: 'analyst@zerospoils.local',
    name: 'Data Analyst',
    role: 'analyst' as const,
  },
  support: {
    id: 'user-support-001',
    email: 'support@zerospoils.local',
    name: 'Support Agent',
    role: 'support' as const,
  },
};

// Mock valid auth tokens (email -> token)
export const MOCK_AUTH_TOKENS: Record<string, string> = {
  'admin@zerospoils.local': 'token_admin_abc123',
  'analyst@zerospoils.local': 'token_analyst_xyz789',
  'support@zerospoils.local': 'token_support_def456',
};

// Mock metrics data (time series)
export function generateMockMetrics(): MetricsSnapshot {
  const now = new Date();
  return {
    timestamp: now.toISOString(),
    newInstalls: Math.floor(Math.random() * 500) + 50,
    activeUsers: Math.floor(Math.random() * 2000) + 300,
    crashFreeRate: 0.97 + Math.random() * 0.03, // 97-100%
    d1Retention: 0.45 + Math.random() * 0.15, // 45-60%
    avgSessionLength: Math.floor(Math.random() * 300) + 60, // 60-360 seconds
    itemsAdded: Math.floor(Math.random() * 3000) + 500,
    notificationOptInRate: 0.72 + Math.random() * 0.18, // 72-90%
  };
}

// Generate historical metrics (last 24 hours)
export function generateMetricsHistory(hours: number = 24): MetricsSnapshot[] {
  const metrics: MetricsSnapshot[] = [];
  const now = new Date();

  for (let i = hours; i >= 0; i--) {
    const timestamp = new Date(now.getTime() - i * 60 * 60 * 1000);
    metrics.push({
      timestamp: timestamp.toISOString(),
      newInstalls: Math.floor(Math.random() * 500) + 50,
      activeUsers: Math.floor(Math.random() * 2000) + 300,
      crashFreeRate: 0.97 + Math.random() * 0.03,
      d1Retention: 0.45 + Math.random() * 0.15,
      avgSessionLength: Math.floor(Math.random() * 300) + 60,
      itemsAdded: Math.floor(Math.random() * 3000) + 500,
      notificationOptInRate: 0.72 + Math.random() * 0.18,
    });
  }

  return metrics;
}

// Mock feedback items
export function generateMockFeedback(): Feedback[] {
  return [
    {
      id: uuidv4(),
      userId: 'user-123',
      type: 'bug',
      title: 'App crashes when adding items with special characters',
      description: 'Reproducible crash when item name contains emoji',
      severity: 'high',
      status: 'triaged',
      createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      triageNote: 'Assigned to mobile team - likely input validation bug',
      triageEmail: 'analyst@zerospoils.local',
    },
    {
      id: uuidv4(),
      userId: 'user-456',
      type: 'feature_request',
      title: 'Add barcode scanning for faster item entry',
      description: 'Would love to scan product barcodes instead of typing',
      status: 'untriaged',
      createdAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: uuidv4(),
      userId: 'user-789',
      type: 'general',
      title: 'Great app, very useful!',
      description: 'Using this to track grocery items at home. Love the expiry date reminders.',
      status: 'untriaged',
      createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    },
  ];
}

// Mock telemetry events
export function generateMockTelemetryEvents(count: number = 20): TelemetryEvent[] {
  const events: TelemetryEvent[] = [];
  const eventNames = [
    'app_open',
    'item_added',
    'item_consumed',
    'notification_opt_in',
    'onboarding_complete',
    'settings_changed',
  ];
  const platforms = ['ios', 'android'] as const;

  for (let i = 0; i < count; i++) {
    events.push({
      id: uuidv4(),
      eventName: eventNames[Math.floor(Math.random() * eventNames.length)],
      userId: `user-${Math.floor(Math.random() * 10000)}`,
      platform: platforms[Math.floor(Math.random() * platforms.length)],
      appVersion: '0.1.0',
      timestamp: new Date(Date.now() - Math.random() * 60 * 60 * 1000).toISOString(),
      properties: {
        duration: Math.floor(Math.random() * 300),
        category: 'grocery',
      },
    });
  }

  return events;
}

// In-memory store for demo (persists across requests within a session)
export const mockDataStore = {
  feedback: generateMockFeedback(),
  telemetryEvents: generateMockTelemetryEvents(50),
  metricsHistory: generateMetricsHistory(24),

  // Mark feedback as triaged
  triageFeedback(id: string, note: string, email: string): void {
    const item = this.feedback.find((f) => f.id === id);
    if (item) {
      item.status = 'triaged';
      item.triageNote = note;
      item.triageEmail = email;
    }
  },

  // Add new feedback
  addFeedback(feedback: Feedback): void {
    this.feedback.push(feedback);
  },
};
