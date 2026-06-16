/**
 * Firebase Remote Config management service
 *
 * Delegates to the real Firebase Admin SDK when FIREBASE_PROJECT_ID is set,
 * otherwise falls back to the in-process mock so local dev / unit tests work
 * with no credentials.
 */

import {
  RemoteConfigTemplate,
  RemoteConfigParameterDef,
  RemoteConfigCondition,
  RemoteConfigChangeAudit,
  PublishRequest,
  PublishResponse,
  ValidationResponse,
} from '../types/remoteConfig.js';
import { getRemoteConfigClient, getFirebaseMode } from './firebaseAdmin.js';

// ---------------------------------------------------------------------------
// SDK ↔ domain-type helpers
// ---------------------------------------------------------------------------

function sdkParamToDomain(sdkParams: Record<string, any>): Record<string, RemoteConfigParameterDef> {
  const result: Record<string, RemoteConfigParameterDef> = {};
  for (const [key, p] of Object.entries(sdkParams)) {
    const conditionalValues: Record<string, { value: string }> = {};
    if (p.conditionalValues) {
      for (const [cName, cVal] of Object.entries(p.conditionalValues as Record<string, any>)) {
        conditionalValues[cName] = { value: String(cVal?.value ?? '') };
      }
    }
    result[key] = {
      defaultValue: { value: String(p.defaultValue?.value ?? '') },
      ...(Object.keys(conditionalValues).length ? { conditionalValues } : {}),
      ...(p.description ? { description: String(p.description) } : {}),
      ...(p.valueType ? { valueType: p.valueType as RemoteConfigParameterDef['valueType'] } : {}),
    };
  }
  return result;
}

function sdkConditionsToDomain(sdkConditions: any[]): RemoteConfigCondition[] {
  return (sdkConditions ?? []).map((c: any) => ({
    name: String(c.name),
    expression: String(c.expression),
    ...(c.tagColor ? { tagColor: String(c.tagColor) } : {}),
  }));
}

function domainParamsToSdk(params: Record<string, RemoteConfigParameterDef>): Record<string, any> {
  const result: Record<string, any> = {};
  for (const [key, p] of Object.entries(params)) {
    const conditionalValues: Record<string, any> = {};
    if (p.conditionalValues) {
      for (const [cName, cVal] of Object.entries(p.conditionalValues)) {
        conditionalValues[cName] = { value: cVal.value };
      }
    }
    result[key] = {
      defaultValue: { value: p.defaultValue.value },
      ...(Object.keys(conditionalValues).length ? { conditionalValues } : {}),
      ...(p.description ? { description: p.description } : {}),
      ...(p.valueType ? { valueType: p.valueType } : {}),
    };
  }
  return result;
}

// ---------------------------------------------------------------------------
// Local mock (used when Firebase is not configured)
// ---------------------------------------------------------------------------

let mockTemplate: RemoteConfigTemplate = {
  etag: 'v1-initial',
  parameters: {
    'feature_flags.new_dashboard': {
      defaultValue: { value: 'true' },
      description: 'Enable new dashboard UI',
      valueType: 'BOOLEAN',
    },
    'feature_flags.advanced_analytics': {
      defaultValue: { value: 'false' },
      description: 'Enable advanced analytics features',
      valueType: 'BOOLEAN',
    },
    'config.dashboard_refresh_interval': {
      defaultValue: { value: '30' },
      description: 'Dashboard refresh interval in seconds',
      valueType: 'NUMBER',
    },
    'config.analytics_config': {
      defaultValue: { value: '{"sampleRate":0.1,"batchSize":100}' },
      description: 'Analytics configuration as JSON',
      valueType: 'JSON',
    },
  },
  conditions: [
    { name: 'users_in_us', expression: 'device.country in ["US"]', tagColor: 'blue' },
    { name: 'beta_testers', expression: 'user.email matches_regex ".*@beta\\.example\\.com"', tagColor: 'green' },
  ],
  version: {
    versionNumber: '1',
    updateUser: 'system',
    updateTime: new Date().toISOString(),
  },
};

const auditTrail: RemoteConfigChangeAudit[] = [];

const versionHistory: Array<RemoteConfigTemplate & { versionNumber: string }> = [
  { ...mockTemplate, versionNumber: '1' },
];

// ---------------------------------------------------------------------------
// Validation (shared between mock and live paths)
// ---------------------------------------------------------------------------

function validateParameter(key: string, param: RemoteConfigParameterDef): ValidationResponse {
  const errors: Array<{ field: string; message: string }> = [];

  if (!param.defaultValue || !param.defaultValue.value) {
    errors.push({ field: `${key}.defaultValue`, message: 'Default value is required' });
  }

  const valueType = param.valueType || 'STRING';

  if (valueType === 'BOOLEAN') {
    const val = param.defaultValue.value?.toLowerCase();
    if (!['true', 'false'].includes(val)) {
      errors.push({ field: `${key}.defaultValue`, message: `Expected boolean ("true"/"false"), got "${param.defaultValue.value}"` });
    }
  } else if (valueType === 'NUMBER') {
    if (isNaN(parseFloat(param.defaultValue.value || ''))) {
      errors.push({ field: `${key}.defaultValue`, message: `Expected number, got "${param.defaultValue.value}"` });
    }
  } else if (valueType === 'JSON') {
    try { JSON.parse(param.defaultValue.value || ''); } catch {
      errors.push({ field: `${key}.defaultValue`, message: `Invalid JSON: ${param.defaultValue.value}` });
    }
  }

  if (param.conditionalValues) {
    Object.entries(param.conditionalValues).forEach(([condName, condVal]) => {
      if (valueType === 'BOOLEAN' && !['true', 'false'].includes(condVal.value?.toLowerCase() || '')) {
        errors.push({ field: `${key}.conditionalValues.${condName}`, message: `Expected boolean, got "${condVal.value}"` });
      } else if (valueType === 'NUMBER' && isNaN(parseFloat(condVal.value || ''))) {
        errors.push({ field: `${key}.conditionalValues.${condName}`, message: `Expected number, got "${condVal.value}"` });
      } else if (valueType === 'JSON') {
        try { JSON.parse(condVal.value || ''); } catch {
          errors.push({ field: `${key}.conditionalValues.${condName}`, message: `Invalid JSON: ${condVal.value}` });
        }
      }
    });
  }

  return { valid: errors.length === 0, errors };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export async function getCurrentTemplate(): Promise<RemoteConfigTemplate> {
  const rc = getRemoteConfigClient();
  if (!rc) return mockTemplate;

  const tpl = await rc.getTemplate();
  return {
    etag: (tpl as any).etag ?? '',
    parameters: sdkParamToDomain((tpl.parameters ?? {}) as Record<string, any>),
    conditions: sdkConditionsToDomain((tpl.conditions ?? []) as any[]),
    version: tpl.version ? {
      versionNumber: String(tpl.version.versionNumber ?? ''),
      updateUser: String((tpl.version as any).updateUser?.email ?? (tpl.version as any).updateUser ?? 'unknown'),
      updateTime: tpl.version.updateTime ? new Date(tpl.version.updateTime as any).toISOString() : new Date().toISOString(),
    } : undefined,
  };
}

export async function getTemplateHistory(limit: number = 20): Promise<RemoteConfigChangeAudit[]> {
  return auditTrail.slice(0, Math.max(1, Math.min(limit, 100)));
}

export async function validatePublish(req: PublishRequest): Promise<ValidationResponse> {
  const errors: Array<{ field: string; message: string }> = [];

  // Check etag matches current template
  const current = await getCurrentTemplate();
  if (req.etag !== current.etag) {
    errors.push({ field: 'etag', message: `Stale etag. Expected "${current.etag}", got "${req.etag}"` });
  }

  Object.entries(req.parameters || {}).forEach(([key, param]) => {
    errors.push(...validateParameter(key, param).errors);
  });

  if (req.conditions) {
    req.conditions.forEach((cond, idx) => {
      if (!cond.name) errors.push({ field: `conditions[${idx}].name`, message: 'Condition name is required' });
      if (!cond.expression) errors.push({ field: `conditions[${idx}].expression`, message: 'Condition expression is required' });
    });
  }

  return { valid: errors.length === 0, errors };
}

export async function publishTemplate(req: PublishRequest, user: string): Promise<PublishResponse> {
  const current = await getCurrentTemplate();

  if (req.etag !== current.etag) {
    return { success: false, error: { code: 'ETAG_MISMATCH', message: `Template was modified. Current etag: ${current.etag}. Your etag: ${req.etag}`, field: 'etag' } };
  }

  const validation = await validatePublish(req);
  if (!validation.valid) {
    return { success: false, error: { code: 'VALIDATION_ERROR', message: 'One or more validation errors occurred', field: validation.errors[0]?.field } };
  }

  const rc = getRemoteConfigClient();

  if (rc) {
    // --- Live Firebase path ---
    try {
      const sdkTemplate = await rc.getTemplate();
      (sdkTemplate as any).parameters = domainParamsToSdk(req.parameters);
      if (req.conditions) {
        (sdkTemplate as any).conditions = req.conditions;
      }
      const published = await rc.publishTemplate(sdkTemplate);
      const newEtag = (published as any).etag ?? `live-${Date.now()}`;
      const newVersion = published.version ? {
        versionNumber: String(published.version.versionNumber ?? ''),
        updateUser: user,
        updateTime: new Date().toISOString(),
      } : undefined;

      const after = await getCurrentTemplate();
      recordAudit('publish', user, current, after, req.correlationId);

      return { success: true, newEtag, newVersion };
    } catch (err: any) {
      // Etag conflict from Firebase
      if (err?.code === 'remote-config/version-mismatch' || err?.httpErrorCode?.status === 409) {
        return { success: false, error: { code: 'ETAG_MISMATCH', message: 'Remote template was modified concurrently. Refresh and try again.', field: 'etag' } };
      }
      return { success: false, error: { code: 'FIREBASE_ERROR', message: String(err?.message ?? err) } };
    }
  }

  // --- Mock path ---
  const newEtag = `v${parseInt(mockTemplate.etag.split('-')[0]?.substring(1) || '1', 10) + 1}-${Date.now()}`;
  const oldTemplate = { ...mockTemplate };

  mockTemplate = {
    etag: newEtag,
    parameters: req.parameters,
    conditions: req.conditions ?? mockTemplate.conditions,
    version: {
      versionNumber: String(parseInt(mockTemplate.version?.versionNumber || '1', 10) + 1),
      updateUser: user,
      updateTime: new Date().toISOString(),
    },
  };

  recordAudit('publish', user, oldTemplate, mockTemplate, req.correlationId);
  versionHistory.unshift({ ...mockTemplate, versionNumber: mockTemplate.version!.versionNumber });

  return { success: true, newEtag, newVersion: mockTemplate.version };
}

export async function rollbackTemplate(targetVersionNumber: string, user: string, correlationId: string): Promise<PublishResponse> {
  const rc = getRemoteConfigClient();

  if (rc) {
    // --- Live Firebase path ---
    try {
      const versionNum = parseInt(targetVersionNumber, 10);
      if (isNaN(versionNum)) {
        return { success: false, error: { code: 'INVALID_VERSION', message: `Invalid version number: ${targetVersionNumber}` } };
      }
      const current = await getCurrentTemplate();
      const rolledBack = await rc.rollback(versionNum);
      const newEtag = (rolledBack as any).etag ?? `live-rollback-${Date.now()}`;
      const after = await getCurrentTemplate();
      recordAudit('rollback', user, current, after, correlationId);
      return { success: true, newEtag, newVersion: after.version };
    } catch (err: any) {
      return { success: false, error: { code: 'FIREBASE_ERROR', message: String(err?.message ?? err) } };
    }
  }

  // --- Mock path ---
  const target = versionHistory.find((v) => v.versionNumber === targetVersionNumber);
  if (!target) {
    return { success: false, error: { code: 'VERSION_NOT_FOUND', message: `Version ${targetVersionNumber} not found in history` } };
  }

  const oldTemplate = { ...mockTemplate };
  const newEtag = `v${parseInt(mockTemplate.etag.split('-')[0]?.substring(1) || '1', 10) + 1}-${Date.now()}`;

  mockTemplate = {
    etag: newEtag,
    parameters: { ...target.parameters },
    conditions: [...(target.conditions ?? [])],
    version: {
      versionNumber: String(parseInt(mockTemplate.version?.versionNumber || '1', 10) + 1),
      updateUser: user,
      updateTime: new Date().toISOString(),
    },
  };

  recordAudit('rollback', user, oldTemplate, mockTemplate, correlationId);
  versionHistory.unshift({ ...mockTemplate, versionNumber: mockTemplate.version!.versionNumber });

  return { success: true, newEtag, newVersion: mockTemplate.version };
}

export async function getVersionHistory(limit: number = 50): Promise<Array<{ versionNumber: string; updateTime: string; updateUser: string }>> {
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(limit, 100)) : 50;

  const rc = getRemoteConfigClient();
  if (rc) {
    try {
      const list = await rc.listVersions({ pageSize: safeLimit });
      return (list.versions ?? []).map((v: any) => ({
        versionNumber: String(v.versionNumber ?? ''),
        updateTime: v.updateTime ? new Date(v.updateTime).toISOString() : '',
        updateUser: String(v.updateUser?.email ?? v.updateUser ?? 'unknown'),
      }));
    } catch {
      // fall through to mock
    }
  }

  return versionHistory.slice(0, safeLimit).map((v) => ({
    versionNumber: v.versionNumber,
    updateTime: v.version?.updateTime ?? new Date().toISOString(),
    updateUser: v.version?.updateUser ?? 'unknown',
  }));
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function recordAudit(
  action: 'publish' | 'rollback',
  user: string,
  before: RemoteConfigTemplate,
  after: RemoteConfigTemplate,
  correlationId?: string,
): void {
  auditTrail.unshift({
    id: `audit-${Date.now()}`,
    timestamp: new Date().toISOString(),
    user,
    action,
    before,
    after,
    correlationId: correlationId ?? '',
  });
  if (auditTrail.length > 100) auditTrail.pop();
}

export function getMode(): string {
  return getFirebaseMode();
}


