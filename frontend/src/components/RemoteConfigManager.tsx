/**
 * Remote Config Management Page - Admin UI for editing parameters and conditions
 */

import React, { useState, useEffect } from 'react';
import { Form, Button, Table, Tag, Space, Modal, Input, Select, message } from 'antd';
import { EditOutlined, RollbackOutlined } from '@ant-design/icons';
import type { RemoteConfigTemplate, RemoteConfigParameterDef } from '../types';
import { api } from '../utils/api';

interface RemoteConfigManagerProps {
  onSave?: (template: RemoteConfigTemplate) => void;
}

export const RemoteConfigManager: React.FC<RemoteConfigManagerProps> = ({ onSave }) => {
  const [template, setTemplate] = useState<RemoteConfigTemplate | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [editingValue, setEditingValue] = useState<RemoteConfigParameterDef | null>(null);
  const [saving, setSaving] = useState(false);
  const [historyVisible, setHistoryVisible] = useState(false);

  useEffect(() => {
    const fetchTemplate = async () => {
      try {
        const response = await api.getRemoteConfigTemplate();
        const data = response.data;
        setTemplate(data.template);
        setLoading(false);
      } catch (error) {
        message.error(`Failed to load remote config: ${error}`);
        setLoading(false);
      }
    };

    fetchTemplate();
  }, []);

  const handleEditParameter = (key: string, param: RemoteConfigParameterDef) => {
    setEditingKey(key);
    setEditingValue({ ...param });
  };

  const handleSaveParameter = async () => {
    if (!template || !editingKey || !editingValue) return;

    setSaving(true);
    try {
      // Validate the parameter change
      const validationResponse = await api.validateRemoteConfig({
        parameters: { [editingKey]: editingValue },
        etag: template.etag,
      });

      const validation = validationResponse.data;
      if (!validation.valid) {
        message.error(`Validation error: ${validation.errors[0]?.message}`);
        return;
      }

      // Publish the change
      const publishResponse = await api.publishRemoteConfig({
        parameters: {
          ...template.parameters,
          [editingKey]: editingValue,
        },
        conditions: template.conditions,
        etag: template.etag,
      });

      const result = publishResponse.data;
      const updatedTemplate = {
        ...template,
        etag: result.newEtag,
        parameters: {
          ...template.parameters,
          [editingKey]: editingValue,
        },
      };
      setTemplate(updatedTemplate);
      setEditingKey(null);
      setEditingValue(null);
      message.success('Parameter updated successfully');
      onSave?.(updatedTemplate);
    } catch (error) {
      const axiosError = error as {
        response?: { status?: number; data?: { error?: string | { message?: string } } };
      };
      if (axiosError.response?.status === 409) {
        message.error('Template was modified by another user. Please refresh.');
      } else {
        const serverError = axiosError.response?.data?.error;
        const serverMsg =
          typeof serverError === 'string'
            ? serverError
            : serverError?.message;
        message.error(`Failed to save: ${serverMsg ?? String(error)}`);
      }
    } finally {
      setSaving(false);
    }
  };

  const handleCancel = () => {
    setEditingKey(null);
    setEditingValue(null);
  };

  const columns = [
    {
      title: 'Parameter Name',
      dataIndex: 'key',
      key: 'key',
    },
    {
      title: 'Value Type',
      dataIndex: 'valueType',
      key: 'valueType',
      render: (valueType: string) => (
        <Tag color={valueType === 'BOOLEAN' ? 'blue' : valueType === 'JSON' ? 'purple' : 'green'}>
          {valueType || 'STRING'}
        </Tag>
      ),
    },
    {
      title: 'Default Value',
      dataIndex: 'defaultValue',
      key: 'defaultValue',
      render: (defaultValue: any) => (
        <code>{defaultValue?.value?.substring(0, 50)}</code>
      ),
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (description: string) => description || '-',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: any, record: any) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            onClick={() => handleEditParameter(record.key, record.param)}
            size="small"
          >
            Edit
          </Button>
        </Space>
      ),
    },
  ];

  const dataSource = template
    ? Object.entries(template.parameters).map(([key, param]: [string, RemoteConfigParameterDef]) => ({
        key,
        param,
        valueType: param.valueType || 'STRING',
        defaultValue: param.defaultValue,
        description: param.description,
      }))
    : [];

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between' }}>
        <h2>Remote Config Parameters</h2>
        <Space>
          <Button icon={<RollbackOutlined />} onClick={() => setHistoryVisible(true)}>
            Rollback
          </Button>
        </Space>
      </div>

      <Table
        dataSource={dataSource}
        columns={columns}
        loading={loading}
        rowKey="key"
        pagination={{ pageSize: 10 }}
      />

      <Modal
        title={`Edit Parameter: ${editingKey}`}
        open={!!editingKey}
        onOk={handleSaveParameter}
        onCancel={handleCancel}
        confirmLoading={saving}
      >
        {editingValue && (
          <Form layout="vertical">
            <Form.Item label="Value Type">
              <Select
                value={editingValue.valueType || 'STRING'}
                onChange={(value) =>
                  setEditingValue({
                    ...editingValue,
                    valueType: value as any,
                  })
                }
                options={[
                  { label: 'String', value: 'STRING' },
                  { label: 'Boolean', value: 'BOOLEAN' },
                  { label: 'Number', value: 'NUMBER' },
                  { label: 'JSON', value: 'JSON' },
                ]}
              />
            </Form.Item>

            <Form.Item label="Default Value">
              <Input.TextArea
                value={editingValue.defaultValue?.value}
                onChange={(e) =>
                  setEditingValue({
                    ...editingValue,
                    defaultValue: { value: e.target.value },
                  })
                }
                rows={3}
              />
            </Form.Item>

            <Form.Item label="Description">
              <Input
                value={editingValue.description || ''}
                onChange={(e) =>
                  setEditingValue({
                    ...editingValue,
                    description: e.target.value,
                  })
                }
              />
            </Form.Item>
          </Form>
        )}
      </Modal>

      <Modal
        title="Version Rollback"
        open={historyVisible}
        onCancel={() => setHistoryVisible(false)}
        width={600}
      >
        <p>Rollback history coming soon...</p>
      </Modal>
    </div>
  );
};

export default RemoteConfigManager;
