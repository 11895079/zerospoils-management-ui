/**
 * ETL Job for BullMQ
 *
 * Scheduled to run every 10 minutes. Orchestrates the complete
 * telemetry ETL pipeline: extract, normalize, validate, redact,
 * deduplicate, load, and refresh marts.
 */

import { Job } from 'bullmq';
import { Database } from 'duckdb';
import {
  extract,
  normalize,
  validate,
  redact,
  generateStableFactId,
  load,
  refreshMarts,
  loadRedactionPolicies,
  TelemetryEvent,
} from '../etl';

export interface ETLJobData {
  source: 'zerospoils' | 'mock';
  force_refresh: boolean;
}

/**
 * Process ETL job
 * Returns summary of what was processed
 */
export async function processETLJob(
  job: Job<ETLJobData>,
  db: Database
): Promise<{
  status: 'success' | 'failure';
  raw_events: number;
  processed_events: number;
  validation_failures: number;
  redacted_fields: number;
  masked_fields: number;
  load_id: string;
  duration_ms: number;
}> {
  const startTime = Date.now();
  const source = job.data.source || 'mock';

  try {
    console.log(`[ETL Job] Starting ETL pipeline (source: ${source})`);

    // Load redaction policies
    const policies = loadRedactionPolicies();
    const defaultPolicy = policies.default;

    // Phase 1: Extract
    job.progress(10);
    console.log('[ETL Job] Phase 1: Extracting events');
    const rawEvents = await extract(source);
    console.log(`[ETL Job] Extracted ${rawEvents.length} raw events`);

    // Phase 2: Normalize
    job.progress(25);
    console.log('[ETL Job] Phase 2: Normalizing events');
    let normalizedEvents = rawEvents.map(normalize);

    // Phase 3: Validate
    job.progress(40);
    console.log('[ETL Job] Phase 3: Validating events');
    let validationFailures = 0;
    const validatedEvents: TelemetryEvent[] = [];

    for (const event of normalizedEvents) {
      const validationResult = validate(event);
      if (validationResult.valid) {
        validatedEvents.push(event);
      } else {
        validationFailures++;
        console.warn(`[ETL Job] Validation failed for event:`, validationResult.errors);
      }
    }

    console.log(`[ETL Job] Validated ${validatedEvents.length} events, ${validationFailures} failures`);

    // Phase 4: Redact PII
    job.progress(55);
    console.log('[ETL Job] Phase 4: Redacting PII fields');
    let totalRedactedFields = 0;
    let totalMaskedFields = 0;

    const redactedEvents = validatedEvents.map(event => {
      // Count fields before redaction
      const fieldsBefore = Object.keys(event).length;
      const redactedEvent = redact(event, defaultPolicy);
      const fieldsAfter = Object.keys(redactedEvent).length;

      totalRedactedFields += Math.max(0, fieldsBefore - fieldsAfter);

      // Count masked fields (simple heuristic: fields that changed)
      for (const [field, value] of Object.entries(redactedEvent)) {
        if (defaultPolicy.masked_fields[field] && event[field] !== value) {
          totalMaskedFields++;
        }
      }

      return redactedEvent;
    });

    console.log(
      `[ETL Job] Redacted ${totalRedactedFields} fields, masked ${totalMaskedFields} fields`
    );

    // Phase 5: Deduplicate using stable fact IDs
    job.progress(70);
    console.log('[ETL Job] Phase 5: Deduplicating events');
    const eventMap = new Map<string, TelemetryEvent>();

    for (const event of redactedEvents) {
      const factId = generateStableFactId(event);
      if (!eventMap.has(factId)) {
        eventMap.set(factId, event);
      }
    }

    const deduplicatedEvents = Array.from(eventMap.values());
    console.log(
      `[ETL Job] Deduplicated ${redactedEvents.length} → ${deduplicatedEvents.length} events`
    );

    // Phase 6: Load into DuckDB
    job.progress(80);
    console.log('[ETL Job] Phase 6: Loading into DuckDB');
    const metadata = await load(db, deduplicatedEvents, {
      redacted_fields_count: totalRedactedFields,
      masked_fields_count: totalMaskedFields,
      validation_failures: validationFailures,
    });

    // Phase 7: Refresh analytics marts
    job.progress(90);
    console.log('[ETL Job] Phase 7: Refreshing analytics marts');
    const martDuration = await refreshMarts(db, metadata.load_id);

    job.progress(100);
    const totalDuration = Date.now() - startTime;

    console.log(`[ETL Job] ETL pipeline completed in ${totalDuration}ms`);
    console.log(`[ETL Job] Load ID: ${metadata.load_id}`);

    return {
      status: 'success',
      raw_events: rawEvents.length,
      processed_events: deduplicatedEvents.length,
      validation_failures: validationFailures,
      redacted_fields: totalRedactedFields,
      masked_fields: totalMaskedFields,
      load_id: metadata.load_id,
      duration_ms: totalDuration,
    };
  } catch (error) {
    console.error('[ETL Job] Pipeline failed:', error);
    throw error;
  }
}
