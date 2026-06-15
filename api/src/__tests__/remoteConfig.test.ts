/**
 * Tests for Remote Config service
 */

import {
  getCurrentTemplate,
  validatePublish,
  publishTemplate,
  rollbackTemplate,
  getVersionHistory,
} from '../services/remoteConfigService.js';

describe('remoteConfigService', () => {
  it('getCurrentTemplate returns initial template', async () => {
    const template = await getCurrentTemplate();
    expect(template.etag).toBeDefined();
    expect(template.parameters).toBeDefined();
    expect(Object.keys(template.parameters).length).toBeGreaterThan(0);
    expect(template.conditions).toBeDefined();
  });

  it('validatePublish rejects invalid BOOLEAN values', async () => {
    const result = await validatePublish({
      parameters: {
        test_flag: {
          defaultValue: { value: 'maybe' },
          valueType: 'BOOLEAN',
        },
      },
      etag: 'v1-initial',
      correlationId: 'test-1',
    });

    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('validatePublish rejects invalid NUMBER values', async () => {
    const result = await validatePublish({
      parameters: {
        interval: {
          defaultValue: { value: 'not-a-number' },
          valueType: 'NUMBER',
        },
      },
      etag: 'v1-initial',
      correlationId: 'test-2',
    });

    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  it('validatePublish rejects invalid JSON values', async () => {
    const result = await validatePublish({
      parameters: {
        config: {
          defaultValue: { value: '{invalid json}' },
          valueType: 'JSON',
        },
      },
      etag: 'v1-initial',
      correlationId: 'test-3',
    });

    expect(result.valid).toBe(false);
  });

  it('validatePublish rejects stale etag', async () => {
    const result = await validatePublish({
      parameters: {
        test: {
          defaultValue: { value: 'test' },
        },
      },
      etag: 'v0-stale',
      correlationId: 'test-4',
    });

    expect(result.valid).toBe(false);
    expect(result.errors.some((e) => e.field === 'etag')).toBe(true);
  });

  it('publishTemplate succeeds with valid parameters', async () => {
    const template = await getCurrentTemplate();
    const result = await publishTemplate(
      {
        parameters: {
          new_feature: {
            defaultValue: { value: 'true' },
            valueType: 'BOOLEAN',
          },
        },
        etag: template.etag,
        correlationId: 'test-5',
      },
      'test-user'
    );

    expect(result.success).toBe(true);
    expect(result.newEtag).toBeDefined();
  });

  it('publishTemplate returns conflict on etag mismatch', async () => {
    const result = await publishTemplate(
      {
        parameters: {
          test: {
            defaultValue: { value: 'test' },
          },
        },
        etag: 'v0-wrong',
        correlationId: 'test-6',
      },
      'test-user'
    );

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('ETAG_MISMATCH');
  });

  it('publishTemplate returns validation errors', async () => {
    const template = await getCurrentTemplate();
    const result = await publishTemplate(
      {
        parameters: {
          bad_bool: {
            defaultValue: { value: 'maybe' },
            valueType: 'BOOLEAN',
          },
        },
        etag: template.etag,
        correlationId: 'test-7',
      },
      'test-user'
    );

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('VALIDATION_ERROR');
  });

  it('rollbackTemplate returns error for missing version', async () => {
    const result = await rollbackTemplate('v999-missing', 'user', 'test-10');

    expect(result.success).toBe(false);
    expect(result.error?.code).toBe('VERSION_NOT_FOUND');
  });
});
