/**
 * ETL Pipeline Tests
 *
 * Tests for each ETL phase: extract, normalize, validate, redact,
 * deduplicate, and load operations.
 */

import {
  normalize,
  validate,
  redact,
  generateStableFactId,
  TelemetryEvent,
  loadRedactionPolicies,
} from '../etl';

describe('ETL Pipeline', () => {
  describe('Normalize', () => {
    it('should add default session_id if missing', () => {
      const event: TelemetryEvent = {
        event_type: 'app_installed',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
      };

      const normalized = normalize(event);
      expect(normalized.session_id).toBeDefined();
      expect(normalized.session_id).not.toBe('unknown');
    });

    it('should preserve existing session_id', () => {
      const event: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'android',
        app_version: '1.2.0',
        release_channel: 'stable',
        session_id: 'custom-session-123',
      };

      const normalized = normalize(event);
      expect(normalized.session_id).toBe('custom-session-123');
    });
  });

  describe('Validate', () => {
    it('should accept valid app_installed event', () => {
      const event: TelemetryEvent = {
        event_type: 'app_installed',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
      };

      const result = validate(event);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('should reject event with missing event_type', () => {
      const event: any = {
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
      };

      const result = validate(event);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Missing event_type');
    });

    it('should reject event with invalid platform', () => {
      const event: any = {
        event_type: 'app_installed',
        timestamp: Date.now(),
        platform: 'windows',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
      };

      const result = validate(event);
      expect(result.valid).toBe(false);
      expect(result.errors).toContain('Invalid platform');
    });

    it('should reject event with unknown event_type', () => {
      const event: any = {
        event_type: 'app_crashed',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
      };

      const result = validate(event);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('Unknown event_type'))).toBe(true);
    });
  });

  describe('Redact', () => {
    const policies = loadRedactionPolicies();
    const defaultPolicy = policies.default;

    it('should remove blocked fields', () => {
      const event: TelemetryEvent = {
        event_type: 'app_installed',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
        password: 'secret123',
        email_address: 'user@example.com',
        api_key: 'should-remain',
      };

      const redacted = redact(event, defaultPolicy);

      expect(redacted.password).toBeUndefined();
      expect(redacted.email_address).toBeUndefined();
      expect(redacted.api_key).toBe('should-remain');
    });

    it('should hash masked fields', () => {
      const event: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'test-session',
        user_id: 'user_12345',
        household_id: 'household_6789',
      };

      const redacted = redact(event, defaultPolicy);

      // Check that masked fields are hashed (different from original)
      expect(redacted.user_id).not.toBe('user_12345');
      expect(redacted.household_id).not.toBe('household_6789');

      // Check that they're consistently hashed (same input = same output)
      const redacted2 = redact(event, defaultPolicy);
      expect(redacted.user_id).toBe(redacted2.user_id);
      expect(redacted.household_id).toBe(redacted2.household_id);
    });

    it('should not modify non-sensitive fields', () => {
      const event: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.2.0',
        release_channel: 'beta',
        session_id: 'test-session',
        category_id: 5,
        location_id: 2,
      };

      const redacted = redact(event, defaultPolicy);

      expect(redacted.event_type).toBe('item_added');
      expect(redacted.platform).toBe('ios');
      expect(redacted.category_id).toBe(5);
      expect(redacted.location_id).toBe(2);
    });
  });

  describe('Stable Fact ID Generation', () => {
    it('should generate same ID for identical events', () => {
      const event1: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
        category: 'dairy',
        entry_source: 'manual',
      };

      const event2: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
        category: 'dairy',
        entry_source: 'manual',
      };

      const id1 = generateStableFactId(event1);
      const id2 = generateStableFactId(event2);

      expect(id1).toBe(id2);
    });

    it('should generate different IDs for different events', () => {
      const event1: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
        category: 'dairy',
        entry_source: 'manual',
      };

      const event2: TelemetryEvent = {
        event_type: 'item_added',
        timestamp: Date.now(),
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
        category: 'produce',
        entry_source: 'manual',
      };

      const id1 = generateStableFactId(event1);
      const id2 = generateStableFactId(event2);

      expect(id1).not.toBe(id2);
    });

    it('should generate stable ID independent of timestamp', () => {
      const event1: TelemetryEvent = {
        event_type: 'app_installed',
        timestamp: 1000,
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
      };

      const event2: TelemetryEvent = {
        event_type: 'app_installed',
        timestamp: 5000,
        platform: 'ios',
        app_version: '1.0.0',
        release_channel: 'stable',
        session_id: 'session-1',
        user_id: 'user-123',
      };

      const id1 = generateStableFactId(event1);
      const id2 = generateStableFactId(event2);

      // Same event, different timestamp = should be same ID (dedup)
      expect(id1).toBe(id2);
    });
  });

  describe('Deduplication', () => {
    it('should deduplicate events by stable fact ID', () => {
      const events: TelemetryEvent[] = [
        {
          event_type: 'item_added',
          timestamp: Date.now(),
          platform: 'ios',
          app_version: '1.0.0',
          release_channel: 'stable',
          session_id: 'session-1',
          user_id: 'user-123',
          category: 'dairy',
        },
        {
          event_type: 'item_added',
          timestamp: Date.now() + 1000,
          platform: 'ios',
          app_version: '1.0.0',
          release_channel: 'stable',
          session_id: 'session-1',
          user_id: 'user-123',
          category: 'dairy',
        },
      ];

      const eventMap = new Map<string, TelemetryEvent>();
      for (const event of events) {
        const factId = generateStableFactId(event);
        if (!eventMap.has(factId)) {
          eventMap.set(factId, event);
        }
      }

      expect(eventMap.size).toBe(1);
    });
  });
});
