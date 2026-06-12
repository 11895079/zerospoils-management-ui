import assert from 'node:assert/strict';
import test from 'node:test';
import {
  closeDuckDBMarts,
  getCurrentMetrics,
  getEtlRuns,
  initializeDuckDBMarts,
  recordEtlRun,
} from '../services/duckdbMarts.js';
import { isQueueName } from '../services/etlQueue.js';

test('isQueueName accepts only supported queue identifiers', () => {
  assert.equal(isQueueName('telemetry_etl'), true);
  assert.equal(isQueueName('feedback_processor'), true);
  assert.equal(isQueueName('telemetry_batch'), true);

  assert.equal(isQueueName('etl_pipeline'), false);
  assert.equal(isQueueName(''), false);
  assert.equal(isQueueName('Telemetry_ETL'), false);
});

test('recordEtlRun stores audit history and updates marts on successful runs', async () => {
  await initializeDuckDBMarts('/tmp/test-marts.duckdb');
  const baseline = await getCurrentMetrics();

  assert.ok(baseline);

  await recordEtlRun({
    jobId: 'job-success-1',
    queue: 'telemetry_etl',
    source: 'mock',
    status: 'success',
    processedRecords: 200,
  });

  const updated = await getCurrentMetrics();
  const runs = getEtlRuns(5);

  assert.ok(updated);
  assert.ok(updated.new_installs_24h > baseline.new_installs_24h);
  assert.ok(updated.active_users_24h > baseline.active_users_24h);
  assert.equal(runs.length, 1);
  assert.equal(runs[0].status, 'success');
  assert.equal(runs[0].jobId, 'job-success-1');

  await closeDuckDBMarts();
});

test('recordEtlRun keeps failure diagnostics for recoverability visibility', async () => {
  await initializeDuckDBMarts('/tmp/test-marts.duckdb');

  await recordEtlRun({
    jobId: 'job-failure-1',
    queue: 'telemetry_etl',
    source: 'zerospoils',
    status: 'failure',
    processedRecords: 0,
    error: 'Simulated telemetry ETL failure for retry validation',
  });

  const runs = getEtlRuns(5);

  assert.equal(runs.length, 1);
  assert.equal(runs[0].status, 'failure');
  assert.equal(runs[0].jobId, 'job-failure-1');
  assert.match(runs[0].error ?? '', /retry validation/);

  await closeDuckDBMarts();
});
