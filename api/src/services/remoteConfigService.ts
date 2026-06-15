/**
 * Firebase Remote Config management service
 * Handles template operations, validation, and audit trail
 */

import {
  RemoteConfigTemplate,
  RemoteConfigParameterDef,
  RemoteConfigCondition,
  RemoteConfigChangeAudit,
  PublishRequest,
  PublishResponse,
  ValidationRequest,
  ValidationResponse,
} from '../types/remoteConfig.js';

// Mock Firebase storage
let currentTemplate: RemoteConfigTemplate = {
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
    {
      name: 'users_in_us',
      expression: 'device.country in ["US"]',
      tagColor: 'blue',
    },
    {
      name: 'beta_testers',
      expression: 'user.email matches_regex ".*@beta\\.example\\.com"',
      tagColor: 'green',
    },
  ],
  version: {
    versionNumber: '1',
    updateUser: 'system',
    updateTime: new Date().toISOString(),
  },
};

// Audit trail
const auditTrail: RemoteConfigChangeAudit[] = [];

// Version history
const versionHistory: Array<RemoteConfigTemplate & { versionNumber: string }> = [
  {
    ...currentTemplate,
    versionNumber: '1',
  },
];

function validateParameter(
  key: string,
  param: RemoteConfigParameterDef
): ValidationResponse {
  const errors: Array<{ field: string; message: string }> = [];

  if (!param.defaultValue || !param.defaultValue.value) {
    errors.push({
      field: `${key}.defaultValue`,
      message: 'Default value is required',
    });
  }

  const valueType = param.valueType || 'STRING';

  // Validate types based on valueType
  if (valueType === 'BOOLEAN') {
    const val = param.defaultValue.value?.toLowerCase();
    if (!['true', 'false'].includes(val)) {
      errors.push({
        field: `${key}.defaultValue`,
        message: `Expected boolean ("true"/"false"), got "${param.defaultValue.value}"`,
      });
    }
  } else if (valueType === 'NUMBER') {
    const num = parseFloat(param.defaultValue.value || '');
    if (isNaN(num)) {
      errors.push({
        field: `${key}.defaultValue`,
        message: `Expected number, got "${param.defaultValue.value}"`,
      });
    }
  } else if (valueType === 'JSON') {
    try {
      JSON.parse(param.defaultValue.value || '');
    } catch {
      errors.push({
        field: `${key}.defaultValue`,
        message: `Invalid JSON: ${param.defaultValue.value}`,
      });
    }
  }

  // Validate conditional values if present
  if (param.conditionalValues) {
    Object.entries(param.conditionalValues).forEach(([condName, condVal]) => {
      if (valueType === 'BOOLEAN' && ![' true', 'false'].includes(condVal.value?.toLowerCase() || '')) {
        errors.push({
          field: `${key}.conditionalValues.${condName}`,
          message: `Expected boolean, got "${condVal.value}"`,
        });
      } else if (valueType === 'NUMBER' && isNaN(parseFloat(condVal.value || ''))) {
        errors.push({
          field: `${key}.conditionalValues.${condName}`,
          message: `Expected number, got "${condVal.value}"`,
        });
      } else if (valueType === 'JSON') {
        try {
          JSON.parse(condVal.value || '');
        } catch {
          errors.push({
            field: `${key}.conditionalValues.${condName}`,
            message: `Invalid JSON: ${condVal.value}`,
          });
        }
      }
    });
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export async function getCurrentTemplate(): Promise<RemoteConfigTemplate> {
  return currentTemplate;
}

export async function getTemplateHistory(limit: number = 20): Promise<RemoteConfigChangeAudit[]> {
  return auditTrail.slice(0, Math.max(1, Math.min(limit, 100)));
}

export async function validatePublish(req: PublishRequest): Promise<ValidationResponse> {
  const errors: Array<{ field: string; message: string }> = [];

  // Validate etag
  if (req.etag !== currentTemplate.etag) {
    errors.push({
      field: 'etag',
      message: `Stale etag. Expected "${currentTemplate.etag}", got "${req.etag}"`,
    });
  }

  // Validate all parameters
  Object.entries(req.parameters || {}).forEach(([key, param]) => {
    const validation = validateParameter(key, param);
    errors.push(...validation.errors);
  });

  // Validate conditions if provided
  if (req.conditions) {
    req.conditions.forEach((cond, idx) => {
      if (!cond.name) {
        errors.push({
          field: `conditions[${idx}].name`,
          message: 'Condition name is required',
        });
      }
      if (!cond.expression) {
        errors.push({
          field: `conditions[${idx}].expression`,
          message: 'Condition expression is required',
        });
      }
    });
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export async function publishTemplate(
  req: PublishRequest,
  user: string
): Promise<PublishResponse> {
  // Check etag conflict FIRST before validating parameters
  if (req.etag !== currentTemplate.etag) {
    return {
      success: false,
      error: {
        code: 'ETAG_MISMATCH',
        message: `Template was modified. Current etag: ${currentTemplate.etag}. Your etag: ${req.etag}`,
        field: 'etag',
      },
    };
  }

  // Validate parameters
  const validation = await validatePublish(req);
  if (!validation.valid) {
    return {
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'One or more validation errors occurred',
        field: validation.errors[0]?.field,
      },
    };
  }

  // Create new version
  const newEtag = `v${parseInt(currentTemplate.etag.split('-')[0]?.substring(1) || '1', 10) + 1}-${Date.now()}`;
  const oldTemplate = { ...currentTemplate };

  currentTemplate = {
    etag: newEtag,
    parameters: req.parameters,
    conditions: req.conditions || currentTemplate.conditions,
    version: {
      versionNumber: String(parseInt(currentTemplate.version?.versionNumber || '1', 10) + 1),
      updateUser: user,
      updateTime: new Date().toISOString(),
    },
  };

  // Record audit
  const audit: RemoteConfigChangeAudit = {
    id: `audit-${Date.now()}`,
    timestamp: new Date().toISOString(),
    user,
    action: 'publish',
    before: oldTemplate,
    after: currentTemplate,
    correlationId: req.correlationId,
  };
  auditTrail.unshift(audit);

  // Keep only last 100 audit entries
  if (auditTrail.length > 100) {
    auditTrail.pop();
  }

  // Add to version history
  versionHistory.unshift({
    ...currentTemplate,
    versionNumber: currentTemplate.version?.versionNumber || '1',
  });

  return {
    success: true,
    newEtag,
    newVersion: currentTemplate.version,
  };
}

export async function rollbackTemplate(
  targetVersionNumber: string,
  user: string,
  correlationId: string
): Promise<PublishResponse> {
  const targetVersion = versionHistory.find(
    (v) => v.versionNumber === targetVersionNumber
  );

  if (!targetVersion) {
    return {
      success: false,
      error: {
        code: 'VERSION_NOT_FOUND',
        message: `Version ${targetVersionNumber} not found in history`,
      },
    };
  }

  const oldTemplate = { ...currentTemplate };
  const newEtag = `v${parseInt(currentTemplate.etag.split('-')[0]?.substring(1) || '1', 10) + 1}-${Date.now()}`;

  currentTemplate = {
    etag: newEtag,
    parameters: { ...targetVersion.parameters },
    conditions: [...(targetVersion.conditions || [])],
    version: {
      versionNumber: String(parseInt(currentTemplate.version?.versionNumber || '1', 10) + 1),
      updateUser: user,
      updateTime: new Date().toISOString(),
    },
  };

  // Record audit
  const audit: RemoteConfigChangeAudit = {
    id: `audit-${Date.now()}`,
    timestamp: new Date().toISOString(),
    user,
    action: 'rollback',
    before: oldTemplate,
    after: currentTemplate,
    correlationId,
  };
  auditTrail.unshift(audit);

  if (auditTrail.length > 100) {
    auditTrail.pop();
  }

  versionHistory.unshift({
    ...currentTemplate,
    versionNumber: currentTemplate.version?.versionNumber || '1',
  });

  return {
    success: true,
    newEtag,
    newVersion: currentTemplate.version,
  };
}

export async function getVersionHistory(limit: number = 50): Promise<
  Array<{
    versionNumber: string;
    updateTime: string;
    updateUser: string;
  }>
> {
  const safeLimit = Number.isFinite(limit) ? Math.max(1, Math.min(limit, 100)) : 50;
  return versionHistory
    .slice(0, safeLimit)
    .map((v) => ({
      versionNumber: v.versionNumber,
      updateTime: v.version?.updateTime || new Date().toISOString(),
      updateUser: v.version?.updateUser || 'unknown',
    }));
}
