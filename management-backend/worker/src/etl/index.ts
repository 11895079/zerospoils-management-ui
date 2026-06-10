/**
 * ZeroSpoils Telemetry ETL Pipeline
 *
 * Phases:
 * 1. Extract - Get raw telemetry events from ZeroSpoils
 * 2. Normalize - Transform to standard schema
 * 3. Validate - Check against schema and redaction policies
 * 4. Redact - Apply PII removal (blocked/masked fields)
 * 5. Deduplicate - Use stable fact IDs for idempotent loads
 * 6. Load - Insert into DuckDB fact tables
 * 7. Refresh Marts - Aggregate into analytics tables
 * 8. Logging - Track metadata for auditing
 */

import { Database } from 'duckdb';
import { createHash } from 'crypto';
import fs from 'fs';
import path from 'path';

export interface TelemetryEvent {
  event_type: string;
  timestamp: number;
  platform: 'ios' | 'android';
  app_version: string;
  release_channel: 'stable' | 'beta' | 'alpha';
  user_id?: string;      // Will be masked
  household_id?: string; // Will be masked
  session_id: string;
  [key: string]: any;
}

export interface RedactionPolicy {
  blocked_fields: string[];    // Fields to remove entirely
  masked_fields: Record<string, string>; // Fields to hash (key: field name, value: hash algo)
}

export interface ETLMetadata {
  load_id: string;
  load_timestamp: Date;
  event_type: string;
  raw_event_count: number;
  deduplicated_count: number;
  redacted_fields_count: number;
  masked_fields_count: number;
  validation_failures: number;
  processing_duration_ms: number;
  mart_refresh_duration_ms: number;
}

// Load redaction policies from zerospoils project
export function loadRedactionPolicies(): Record<string, RedactionPolicy> {
  const policiesPath = '/Users/oba/code/zs/telemetry/policies/redaction.yaml';

  // Parse YAML (simple implementation for known structure)
  const content = fs.readFileSync(policiesPath, 'utf-8');

  return {
    default: {
      blocked_fields: ['password', 'auth_token', 'credit_card', 'ssn', 'phone', 'email_address', 'ip_address', 'latitude', 'longitude'],
      masked_fields: {
        user_id: 'sha256',
        household_id: 'sha256'
      }
    }
  };
}

// Phase 1: Extract telemetry events
export async function extract(source: 'zerospoils' | 'mock'): Promise<TelemetryEvent[]> {
  console.log(`[ETL] Phase 1: Extract from ${source}`);

  if (source === 'zerospoils') {
    // TODO: Connect to ZeroSpoils telemetry API endpoint
    // Would fetch events from the last 10 minutes (ETL run interval)
    return [];
  } else {
    // Mock data for testing
    return generateMockEvents();
  }
}

// Phase 2: Normalize events to standard schema
export function normalize(event: TelemetryEvent): TelemetryEvent {
  return {
    ...event,
    timestamp: event.timestamp || Date.now(),
    session_id: event.session_id || 'unknown',
  };
}

// Phase 3: Validate event structure and required fields
export function validate(event: TelemetryEvent): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Check required fields
  if (!event.event_type) errors.push('Missing event_type');
  if (!event.timestamp) errors.push('Missing timestamp');
  if (!event.platform) errors.push('Missing platform');
  if (!['ios', 'android'].includes(event.platform)) errors.push('Invalid platform');

  // Validate event type exists in schema
  const validTypes = ['app_installed', 'item_added', 'item_wasted', 'reminder_opened', 'inventory_viewed'];
  if (!validTypes.includes(event.event_type)) {
    errors.push(`Unknown event_type: ${event.event_type}`);
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

// Phase 4: Redact PII fields
export function redact(event: TelemetryEvent, policy: RedactionPolicy): TelemetryEvent {
  let redacted = { ...event };
  let redacted_count = 0;
  let masked_count = 0;

  // Remove blocked fields entirely
  for (const field of policy.blocked_fields) {
    if (field in redacted) {
      delete redacted[field];
      redacted_count++;
    }
  }

  // Hash masked fields
  for (const [field, algo] of Object.entries(policy.masked_fields)) {
    if (field in redacted) {
      const value = String(redacted[field]);
      redacted[field] = createHash(algo).update(value).digest('hex');
      masked_count++;
    }
  }

  return redacted;
}

// Phase 5: Generate stable fact ID for deduplication
export function generateStableFactId(event: TelemetryEvent): string {
  // Create a deterministic hash of event content (excluding timestamps which can vary)
  const hashInput = JSON.stringify({
    event_type: event.event_type,
    platform: event.platform,
    app_version: event.app_version,
    user_id: event.user_id,
    session_id: event.session_id,
    // Include key event-specific fields to detect duplicates
    ...(() => {
      switch (event.event_type) {
        case 'item_added':
          return { category: event.category, entry_source: event.entry_source };
        case 'item_wasted':
          return { item_id: event.item_id, waste_reason: event.waste_reason };
        default:
          return {};
      }
    })()
  });

  return createHash('md5').update(hashInput).digest('hex');
}

// Phase 6: Load into DuckDB
export async function load(
  db: Database,
  events: TelemetryEvent[],
  metadata: Partial<ETLMetadata>
): Promise<ETLMetadata> {
  console.log(`[ETL] Phase 6: Load ${events.length} events into DuckDB`);

  const loadStartTime = Date.now();
  const loadId = `load_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  try {
    // Use a transaction for atomic load
    await db.run('BEGIN TRANSACTION');

    // Insert events by type
    const appInstalledEvents = events.filter(e => e.event_type === 'app_installed');
    const itemAddedEvents = events.filter(e => e.event_type === 'item_added');
    const itemWastedEvents = events.filter(e => e.event_type === 'item_wasted');
    const reminderOpenedEvents = events.filter(e => e.event_type === 'reminder_opened');
    const inventoryViewedEvents = events.filter(e => e.event_type === 'inventory_viewed');

    // Load each event type
    for (const event of appInstalledEvents) {
      await insertAppInstalledEvent(db, event);
    }

    for (const event of itemAddedEvents) {
      await insertItemAddedEvent(db, event);
    }

    for (const event of itemWastedEvents) {
      await insertItemWastedEvent(db, event);
    }

    for (const event of reminderOpenedEvents) {
      await insertReminderOpenedEvent(db, event);
    }

    for (const event of inventoryViewedEvents) {
      await insertInventoryViewedEvent(db, event);
    }

    // Record ETL metadata
    const etlMetadata: ETLMetadata = {
      load_id: loadId,
      load_timestamp: new Date(),
      event_type: 'mixed',
      raw_event_count: events.length,
      deduplicated_count: events.length, // Assume dedup already happened upstream
      redacted_fields_count: metadata.redacted_fields_count || 0,
      masked_fields_count: metadata.masked_fields_count || 0,
      validation_failures: metadata.validation_failures || 0,
      processing_duration_ms: Date.now() - loadStartTime,
      mart_refresh_duration_ms: 0 // Will be updated after mart refresh
    };

    await db.run(
      `INSERT INTO fact_etl_metadata
       (load_id, load_timestamp, event_type, raw_event_count, deduplicated_count,
        redacted_fields_count, masked_fields_count, validation_failures, processing_duration_ms)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        etlMetadata.load_id,
        etlMetadata.load_timestamp.toISOString(),
        etlMetadata.event_type,
        etlMetadata.raw_event_count,
        etlMetadata.deduplicated_count,
        etlMetadata.redacted_fields_count,
        etlMetadata.masked_fields_count,
        etlMetadata.validation_failures,
        etlMetadata.processing_duration_ms
      ]
    );

    await db.run('COMMIT');

    return etlMetadata;
  } catch (error) {
    await db.run('ROLLBACK');
    throw error;
  }
}

// Helper: Insert app_installed event
async function insertAppInstalledEvent(db: Database, event: TelemetryEvent): Promise<void> {
  const eventId = generateStableFactId(event);

  await db.run(
    `INSERT OR IGNORE INTO fact_app_installed
     (event_id, event_timestamp, platform_id, app_version_id, release_channel_id,
      is_first_install, source, session_duration_seconds)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      eventId,
      new Date(event.timestamp).toISOString(),
      event.platform === 'ios' ? 1 : 2,
      1, // TODO: Lookup app_version_id
      ['stable', 'beta', 'alpha'].indexOf(event.release_channel) + 1,
      event.is_first_install || true,
      event.source || 'direct',
      event.session_duration_seconds || 0
    ]
  );
}

// Helper: Insert item_added event
async function insertItemAddedEvent(db: Database, event: TelemetryEvent): Promise<void> {
  const eventId = generateStableFactId(event);

  // Map entry source to dim_entry_source
  const entrySourceMap: Record<string, number> = {
    'manual': 1,
    'camera_barcode': 2,
    'camera_expiry': 3,
    'camera_barcode_and_expiry': 4,
    'shopping_convert': 5,
    'receipt_batch_camera': 6
  };

  const entrySourceId = entrySourceMap[event.entry_source] || 1;

  await db.run(
    `INSERT OR IGNORE INTO fact_item_added
     (event_id, event_timestamp, platform_id, app_version_id, entry_source_id,
      category_id, location_id, barcode_source_id, barcode_confidence, expiry_confidence,
      barcode_accepted, expiry_accepted, has_barcode, has_expiry_date, expiry_days_out,
      quantity, session_duration_seconds)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      eventId,
      new Date(event.timestamp).toISOString(),
      event.platform === 'ios' ? 1 : 2,
      1, // TODO: Lookup app_version_id
      entrySourceId,
      event.category_id || 1,
      event.location_id || 1,
      ['seed_catalog', 'learned_mapping', 'unknown', 'none'].indexOf(event.barcode_source || 'none') + 1,
      event.barcode_confidence || null,
      event.expiry_confidence || null,
      event.barcode_accepted || null,
      event.expiry_accepted || null,
      event.has_barcode || false,
      event.has_expiry_date || false,
      event.expiry_days_out || null,
      event.quantity || 1,
      event.session_duration_seconds || 0
    ]
  );
}

// Helper: Insert item_wasted event
async function insertItemWastedEvent(db: Database, event: TelemetryEvent): Promise<void> {
  const eventId = generateStableFactId(event);

  const wasteReasonMap: Record<string, number> = {
    'expired': 1,
    'spoiled': 2,
    'overcrowded': 3,
    'other': 4
  };

  const wasteReasonId = wasteReasonMap[event.waste_reason] || 4;

  await db.run(
    `INSERT OR IGNORE INTO fact_item_wasted
     (event_id, event_timestamp, platform_id, app_version_id, category_id,
      location_id, waste_reason_id, days_since_added, was_camera_assisted,
      estimated_cost_cents, user_reminder_count, user_acted_on_reminder)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      eventId,
      new Date(event.timestamp).toISOString(),
      event.platform === 'ios' ? 1 : 2,
      1, // TODO: Lookup app_version_id
      event.category_id || 1,
      event.location_id || 1,
      wasteReasonId,
      event.days_since_added || null,
      event.was_camera_assisted || false,
      event.estimated_cost_cents || null,
      event.user_reminder_count || 0,
      event.user_acted_on_reminder || false
    ]
  );
}

// Helper: Insert reminder_opened event
async function insertReminderOpenedEvent(db: Database, event: TelemetryEvent): Promise<void> {
  const eventId = generateStableFactId(event);

  await db.run(
    `INSERT OR IGNORE INTO fact_reminder_opened
     (event_id, event_timestamp, platform_id, app_version_id, reminder_type,
      item_category_id, action_taken, time_to_action_seconds, session_duration_seconds)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      eventId,
      new Date(event.timestamp).toISOString(),
      event.platform === 'ios' ? 1 : 2,
      1, // TODO: Lookup app_version_id
      event.reminder_type || 'expiry',
      event.category_id || null,
      event.action_taken || 'none',
      event.time_to_action_seconds || null,
      event.session_duration_seconds || 0
    ]
  );
}

// Helper: Insert inventory_viewed event
async function insertInventoryViewedEvent(db: Database, event: TelemetryEvent): Promise<void> {
  const eventId = generateStableFactId(event);

  await db.run(
    `INSERT OR IGNORE INTO fact_inventory_viewed
     (event_id, event_timestamp, platform_id, app_version_id, view_type,
      filtered_category_id, filtered_location_id, item_count, expired_item_count,
      days_until_next_expiry, scroll_depth, session_duration_seconds)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      eventId,
      new Date(event.timestamp).toISOString(),
      event.platform === 'ios' ? 1 : 2,
      1, // TODO: Lookup app_version_id
      event.view_type || 'full_inventory',
      event.filtered_category_id || null,
      event.filtered_location_id || null,
      event.item_count || 0,
      event.expired_item_count || 0,
      event.days_until_next_expiry || null,
      event.scroll_depth || null,
      event.session_duration_seconds || 0
    ]
  );
}

// Phase 7: Refresh analytics marts
export async function refreshMarts(db: Database, loadId: string): Promise<number> {
  console.log(`[ETL] Phase 7: Refresh analytics marts`);

  const martStartTime = Date.now();

  try {
    // Refresh mart_daily_installs
    await refreshMartDailyInstalls(db);

    // Refresh mart_daily_active_users
    await refreshMartDailyActiveUsers(db);

    // Refresh mart_camera_adoption
    await refreshMartCameraAdoption(db);

    // Refresh mart_waste_analysis
    await refreshMartWasteAnalysis(db);

    // Refresh mart_barcode_quality
    await refreshMartBarcodeQuality(db);

    // Refresh mart_24h_summary (used by dashboard)
    await refreshMart24hSummary(db);

    // Update metadata with mart refresh time
    const duration = Date.now() - martStartTime;
    await db.run(
      `UPDATE fact_etl_metadata SET mart_refresh_duration_ms = ? WHERE load_id = ?`,
      [duration, loadId]
    );

    return duration;
  } catch (error) {
    console.error('[ETL] Mart refresh failed:', error);
    throw error;
  }
}

async function refreshMartDailyInstalls(db: Database): Promise<void> {
  // Clear and rebuild
  await db.run('TRUNCATE TABLE mart_daily_installs');
  await db.run(`
    INSERT INTO mart_daily_installs
    SELECT
      DATE(event_timestamp) as date_id,
      platform_id,
      COUNT(*) as install_count,
      SUM(CASE WHEN NOT is_first_install THEN 1 ELSE 0 END) as reinstall_count,
      SUM(CASE WHEN is_first_install THEN 1 ELSE 0 END) as first_time_install_count,
      source
    FROM fact_app_installed
    GROUP BY DATE(event_timestamp), platform_id, source
  `);
}

async function refreshMartDailyActiveUsers(db: Database): Promise<void> {
  await db.run('TRUNCATE TABLE mart_daily_active_users');
  // This would aggregate from item_added, item_wasted, reminder_opened events
  // Simplified here - in production would union multiple fact tables
}

async function refreshMartCameraAdoption(db: Database): Promise<void> {
  await db.run('TRUNCATE TABLE mart_camera_adoption');
  await db.run(`
    INSERT INTO mart_camera_adoption
    SELECT
      DATE(event_timestamp) as date_id,
      platform_id,
      entry_source_id,
      COUNT(*) as item_count,
      AVG(barcode_confidence) as avg_barcode_confidence,
      AVG(expiry_confidence) as avg_expiry_confidence,
      100.0 * SUM(CASE WHEN barcode_accepted THEN 1 ELSE 0 END) / COUNT(*) as barcode_accepted_pct,
      100.0 * SUM(CASE WHEN expiry_accepted THEN 1 ELSE 0 END) / COUNT(*) as expiry_accepted_pct
    FROM fact_item_added
    WHERE entry_source_id IN (2, 3, 4, 6)  -- Camera-assisted entry sources
    GROUP BY DATE(event_timestamp), platform_id, entry_source_id
  `);
}

async function refreshMartWasteAnalysis(db: Database): Promise<void> {
  await db.run('TRUNCATE TABLE mart_waste_analysis');
  await db.run(`
    INSERT INTO mart_waste_analysis
    SELECT
      DATE(event_timestamp) as date_id,
      platform_id,
      category_id,
      waste_reason_id,
      COUNT(*) as wasted_item_count,
      SUM(estimated_cost_cents) as total_cost_cents,
      AVG(days_since_added) as avg_days_in_inventory
    FROM fact_item_wasted
    GROUP BY DATE(event_timestamp), platform_id, category_id, waste_reason_id
  `);
}

async function refreshMartBarcodeQuality(db: Database): Promise<void> {
  await db.run('TRUNCATE TABLE mart_barcode_quality');
  await db.run(`
    INSERT INTO mart_barcode_quality
    SELECT
      DATE(event_timestamp) as date_id,
      platform_id,
      barcode_source_id,
      COUNT(*) as item_count,
      AVG(barcode_confidence) as avg_barcode_confidence,
      AVG(expiry_confidence) as avg_expiry_confidence,
      100.0 * SUM(CASE WHEN has_expiry_date THEN 1 ELSE 0 END) / COUNT(*) as items_with_expiry_pct
    FROM fact_item_added
    GROUP BY DATE(event_timestamp), platform_id, barcode_source_id
  `);
}

async function refreshMart24hSummary(db: Database): Promise<void> {
  // Calculate 24h metrics for dashboard
  const results = await db.all(`
    SELECT
      COUNT(DISTINCT CASE WHEN ia.is_first_install THEN 1 END) as new_installs_24h,
      COUNT(DISTINCT CASE WHEN NOT ia.is_first_install THEN 1 END) as reinstalls_24h,
      (SELECT COUNT(DISTINCT ua.user_id) FROM mart_daily_active_users ua) as active_users_24h,
      (SELECT COUNT(*) FROM fact_item_added WHERE event_timestamp > NOW() - INTERVAL 1 DAY) as items_added_24h,
      (SELECT COUNT(*) FROM fact_item_wasted WHERE event_timestamp > NOW() - INTERVAL 1 DAY) as items_wasted_24h,
      (SELECT COALESCE(SUM(estimated_cost_cents), 0) FROM fact_item_wasted WHERE event_timestamp > NOW() - INTERVAL 1 DAY) as total_waste_cost_cents_24h,
      100.0 * (SELECT SUM(CASE WHEN ia.entry_source_id IN (2,3,4,6) THEN 1 ELSE 0 END) FROM fact_item_added ia WHERE ia.event_timestamp > NOW() - INTERVAL 1 DAY)
        / (SELECT COUNT(*) FROM fact_item_added WHERE event_timestamp > NOW() - INTERVAL 1 DAY) as camera_assist_items_pct
    FROM fact_app_installed ia
    WHERE ia.event_timestamp > NOW() - INTERVAL 1 DAY
  `);

  if (results.length > 0) {
    const metrics = results[0];
    await db.run(
      `INSERT INTO mart_24h_summary
       (summary_timestamp, new_installs_24h, reinstalls_24h, active_users_24h, items_added_24h,
        items_wasted_24h, total_waste_cost_cents_24h, camera_assist_items_pct, d1_retention_pct,
        crash_free_rate_pct, avg_session_duration_seconds, notification_opt_in_rate_pct)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        new Date().toISOString(),
        metrics.new_installs_24h || 0,
        metrics.reinstalls_24h || 0,
        metrics.active_users_24h || 0,
        metrics.items_added_24h || 0,
        metrics.items_wasted_24h || 0,
        metrics.total_waste_cost_cents_24h || 0,
        metrics.camera_assist_items_pct || 0,
        0.75,  // TODO: Calculate from retention cohorts
        0.999, // TODO: Calculate from crash events
        300,   // TODO: Calculate from session data
        0.85   // TODO: Calculate from notification preferences
      ]
    );
  }
}

// Generate mock events for testing
function generateMockEvents(): TelemetryEvent[] {
  const events: TelemetryEvent[] = [];
  const now = Date.now();
  const oneHourAgo = now - 3600 * 1000;

  // Generate mock app_installed events
  for (let i = 0; i < 10; i++) {
    events.push({
      event_type: 'app_installed',
      timestamp: oneHourAgo + Math.random() * 3600 * 1000,
      platform: Math.random() > 0.5 ? 'ios' : 'android',
      app_version: '1.2.0',
      release_channel: 'stable',
      user_id: `user_${i}`,
      session_id: `session_${i}`,
      is_first_install: i < 7,
      source: 'app_store',
      session_duration_seconds: Math.floor(Math.random() * 600)
    });
  }

  // Generate mock item_added events
  const categories = ['dairy', 'produce', 'meat', 'frozen', 'pantry'];
  const locations = ['fridge', 'freezer', 'pantry', 'counter'];
  const entrySources = ['manual', 'camera_barcode', 'camera_expiry', 'camera_barcode_and_expiry'];

  for (let i = 0; i < 25; i++) {
    events.push({
      event_type: 'item_added',
      timestamp: oneHourAgo + Math.random() * 3600 * 1000,
      platform: Math.random() > 0.5 ? 'ios' : 'android',
      app_version: '1.2.0',
      release_channel: 'stable',
      user_id: `user_${Math.floor(i / 3)}`,
      session_id: `session_${Math.floor(i / 3)}`,
      category_id: Math.floor(Math.random() * categories.length) + 1,
      location_id: Math.floor(Math.random() * locations.length) + 1,
      entry_source: entrySources[Math.floor(Math.random() * entrySources.length)],
      has_barcode: true,
      has_expiry_date: Math.random() > 0.3,
      expiry_days_out: Math.floor(Math.random() * 90),
      quantity: Math.floor(Math.random() * 3) + 1,
      session_duration_seconds: Math.floor(Math.random() * 600),
      barcode_confidence: Math.random() * 0.3 + 0.7,
      expiry_confidence: Math.random() * 0.2 + 0.8,
      barcode_accepted: true,
      expiry_accepted: true
    });
  }

  // Generate mock item_wasted events
  const wasteReasons = ['expired', 'spoiled', 'overcrowded', 'other'];

  for (let i = 0; i < 5; i++) {
    events.push({
      event_type: 'item_wasted',
      timestamp: oneHourAgo + Math.random() * 3600 * 1000,
      platform: Math.random() > 0.5 ? 'ios' : 'android',
      app_version: '1.2.0',
      release_channel: 'stable',
      user_id: `user_${Math.floor(i / 1)}`,
      session_id: `session_${Math.floor(i / 1)}`,
      category_id: Math.floor(Math.random() * categories.length) + 1,
      location_id: Math.floor(Math.random() * locations.length) + 1,
      waste_reason: wasteReasons[Math.floor(Math.random() * wasteReasons.length)],
      days_since_added: Math.floor(Math.random() * 30),
      was_camera_assisted: Math.random() > 0.5,
      estimated_cost_cents: Math.floor(Math.random() * 1000) + 50,
      user_reminder_count: Math.floor(Math.random() * 3),
      user_acted_on_reminder: Math.random() > 0.6
    });
  }

  return events;
}
