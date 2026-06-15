/**
 * Firebase Remote Config template types and interfaces
 */

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

export interface RemoteConfigChangeAudit {
  id: string;
  timestamp: string;
  user: string;
  action: 'publish' | 'rollback';
  before: RemoteConfigTemplate;
  after: RemoteConfigTemplate;
  correlationId: string;
}

export interface PublishRequest {
  parameters: Record<string, RemoteConfigParameterDef>;
  conditions?: RemoteConfigCondition[];
  etag: string;
  correlationId: string;
}

export interface PublishResponse {
  success: boolean;
  error?: {
    code: string;
    message: string;
    field?: string;
  };
  newEtag?: string;
  newVersion?: RemoteConfigVersion;
}

export interface ValidationRequest {
  parameter: RemoteConfigParameterDef;
  key?: string;
  valueType?: string;
}

export interface ValidationResponse {
  valid: boolean;
  errors: Array<{
    field: string;
    message: string;
  }>;
}

export interface RollbackRequest {
  targetVersionNumber: string;
  correlationId: string;
}
