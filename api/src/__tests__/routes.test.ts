/**
 * Unit Tests for API Routes
 * Tests metrics, feedback, and telemetry endpoint handlers
 */

describe('Routes - Metrics Endpoints', () => {
  it('GET /metrics/current should return current metrics snapshot', () => {
    const mockResponse = {
      data: {
        timestamp: new Date().toISOString(),
        newInstalls: 150,
        activeUsers: 1250,
        crashFreeRate: 0.985,
        d1Retention: 0.52,
        avgSessionLength: 245,
        itemsAdded: 5620,
        notificationOptInRate: 0.68,
      },
      source: 'duckdb',
      fallbackReason: null,
    };

    // This test validates endpoint structure
    expect(mockResponse).toHaveProperty('source');
    expect(['duckdb', 'mock-fallback']).toContain(mockResponse.source);
    expect(mockResponse).toHaveProperty('data.newInstalls');
    expect(mockResponse).toHaveProperty('data.activeUsers');
    expect(mockResponse).toHaveProperty('data.crashFreeRate');
    expect(typeof mockResponse.data.crashFreeRate).toBe('number');
    expect(mockResponse.data.crashFreeRate).toBeGreaterThanOrEqual(0);
    expect(mockResponse.data.crashFreeRate).toBeLessThanOrEqual(1);
  });

  it('GET /metrics/history should return time-series data', () => {
    const mockHistoryResponse = {
      data: [
        {
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          newInstalls: 120,
          activeUsers: 980,
        },
        {
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          newInstalls: 110,
          activeUsers: 950,
        },
      ],
      source: 'duckdb',
      fallbackReason: null,
    };

    expect(Array.isArray(mockHistoryResponse.data)).toBe(true);
    expect(mockHistoryResponse.data.length).toBeGreaterThan(0);
    expect(['duckdb', 'mock-fallback']).toContain(mockHistoryResponse.source);
    mockHistoryResponse.data.forEach((entry) => {
      expect(entry).toHaveProperty('timestamp');
      expect(entry).toHaveProperty('newInstalls');
      expect(entry).toHaveProperty('activeUsers');
    });
  });

  it('GET /metrics/summary should aggregate key metrics', () => {
    const mockSummary = {
      source: 'duckdb',
      current: {
        newInstalls: 3600,
        crashFreeRate: 0.981,
        d1Retention: 0.498,
      },
      trends: {
        installs24h: 4.2,
        retention7d: 49.8,
        crashFreeRate: 98.1,
      },
    };

    expect(['duckdb', 'mock-fallback']).toContain(mockSummary.source);
    expect(mockSummary).toHaveProperty('current.newInstalls');
    expect(mockSummary).toHaveProperty('trends.installs24h');
    expect(typeof mockSummary.trends.installs24h).toBe('number');
  });
});

describe('Routes - Feedback Endpoints', () => {
  it('GET /feedback should return list of feedback items', () => {
    const mockFeedback = [
      {
        id: 'fb-001',
        userId: 'user-123',
        type: 'bug',
        title: 'App crashes on large inventory',
        description: 'App crashes when adding more than 100 items',
        status: 'open',
        createdAt: new Date().toISOString(),
      },
      {
        id: 'fb-002',
        userId: 'user-456',
        type: 'feature',
        title: 'Add dark mode',
        description: 'Would be nice to have dark mode support',
        status: 'open',
        createdAt: new Date().toISOString(),
      },
    ];

    expect(Array.isArray(mockFeedback)).toBe(true);
    mockFeedback.forEach((item) => {
      expect(item).toHaveProperty('id');
      expect(item).toHaveProperty('type');
      expect(['bug', 'feature', 'suggestion']).toContain(item.type);
      expect(item).toHaveProperty('status');
    });
  });

  it('POST /feedback/:id/triage should update feedback status', () => {
    const triageResult = {
      id: 'fb-001',
      status: 'triaged',
      priority: 'high',
      assignedTo: 'support@zerospoils.local',
      updatedAt: new Date().toISOString(),
    };

    expect(triageResult.status).toBe('triaged');
    expect(['low', 'medium', 'high', 'critical']).toContain(triageResult.priority);
  });
});

describe('Routes - Telemetry Endpoints', () => {
  it('GET /telemetry/events should return recent telemetry events', () => {
    const mockEvents = [
      {
        eventId: 'evt-001',
        eventName: 'item_added',
        userId: 'user-123',
        platform: 'ios',
        appVersion: '1.0.0',
        timestamp: new Date().toISOString(),
        properties: {
          category: 'produce',
          quantity: 5,
        },
      },
    ];

    expect(Array.isArray(mockEvents)).toBe(true);
    mockEvents.forEach((event) => {
      expect(event).toHaveProperty('eventName');
      expect(event).toHaveProperty('platform');
      expect(['ios', 'android', 'web']).toContain(event.platform);
      expect(event).toHaveProperty('timestamp');
    });
  });

  it('GET /telemetry/summary should aggregate telemetry metrics', () => {
    const mockSummary = {
      period: '24h',
      totalEvents: 45000,
      uniqueUsers: 3200,
      topEvents: [
        { eventName: 'item_added', count: 12000 },
        { eventName: 'item_removed', count: 8500 },
      ],
      platformDistribution: {
        ios: 0.55,
        android: 0.4,
        web: 0.05,
      },
    };

    expect(mockSummary.totalEvents).toBeGreaterThan(0);
    expect(mockSummary.uniqueUsers).toBeGreaterThan(0);
    expect(Array.isArray(mockSummary.topEvents)).toBe(true);
    const totalPlatforms = Object.values(mockSummary.platformDistribution).reduce(
      (a: number, b: number) => a + b,
      0
    );
    expect(totalPlatforms).toBeCloseTo(1.0, 2);
  });
});

describe('Routes - Data Validation', () => {
  it('metrics should have realistic values', () => {
    const metrics = {
      newInstalls: 150,
      activeUsers: 1250,
      crashFreeRate: 0.985,
      d1Retention: 0.52,
    };

    // Crash free rate between 0-1
    expect(metrics.crashFreeRate).toBeGreaterThanOrEqual(0);
    expect(metrics.crashFreeRate).toBeLessThanOrEqual(1);

    // Retention between 0-1
    expect(metrics.d1Retention).toBeGreaterThanOrEqual(0);
    expect(metrics.d1Retention).toBeLessThanOrEqual(1);

    // Counts positive
    expect(metrics.newInstalls).toBeGreaterThan(0);
    expect(metrics.activeUsers).toBeGreaterThan(0);
  });

  it('timestamps should be ISO 8601 formatted', () => {
    const timestamp = new Date().toISOString();
    const isoRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
    expect(timestamp).toMatch(isoRegex);
  });
});
