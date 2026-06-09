import React, { useState } from 'react';
import { Card, Form, Input, Button, Select, Alert, Row, Col } from 'antd';
import { useNavigate } from 'react-router-dom';
import { api } from '../utils/api';

const MOCK_CREDENTIALS = [
  {
    email: 'admin@zerospoils.local',
    token: 'token_admin_abc123',
    role: 'admin',
  },
  {
    email: 'analyst@zerospoils.local',
    token: 'token_analyst_xyz789',
    role: 'analyst',
  },
  {
    email: 'support@zerospoils.local',
    token: 'token_support_def456',
    role: 'support',
  },
];

export const Login: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const [form] = Form.useForm();

  const handleQuickLogin = (email: string, token: string, role: string) => {
    setLoading(true);
    api.setToken(token);
    localStorage.setItem('user_role', role);
    setLoading(false);
    navigate('/dashboard');
  };

  const handleSubmit = async (values: { email: string }) => {
    setLoading(true);
    setError(null);

    const cred = MOCK_CREDENTIALS.find((c) => c.email === values.email);
    if (!cred) {
      setError('Invalid email. Use one of the preset emails.');
      setLoading(false);
      return;
    }

    handleQuickLogin(cred.email, cred.token, cred.role);
  };

  return (
    <Row
      justify="center"
      align="middle"
      style={{ minHeight: '100vh', background: '#f5f5f5' }}
    >
      <Col xs={22} sm={20} md={8} lg={6}>
        <Card
          title={<div style={{ textAlign: 'center' }}>🍽️ ZeroSpoils Ops</div>}
          bordered={false}
          style={{ boxShadow: '0 2px 8px rgba(0,0,0,0.15)' }}
        >
          <Alert
            message="Local Development"
            description="This is a local dev environment with mock authentication"
            type="info"
            showIcon
            style={{ marginBottom: '24px' }}
          />

          <Form form={form} onFinish={handleSubmit} layout="vertical">
            <Form.Item
              label="Select Account"
              name="email"
              rules={[{ required: true, message: 'Please select an account' }]}
            >
              <Select placeholder="Choose a test user">
                {MOCK_CREDENTIALS.map((cred) => (
                  <Select.Option key={cred.email} value={cred.email}>
                    {cred.email} ({cred.role})
                  </Select.Option>
                ))}
              </Select>
            </Form.Item>

            {error && (
              <Alert
                message="Error"
                description={error}
                type="error"
                showIcon
                closable
                style={{ marginBottom: '16px' }}
              />
            )}

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                block
                loading={loading}
                size="large"
              >
                Sign In
              </Button>
            </Form.Item>
          </Form>

          <div style={{ textAlign: 'center', marginTop: '24px' }}>
            <div style={{ fontSize: '12px', color: '#666', marginBottom: '12px' }}>
              or quick login as:
            </div>
            {MOCK_CREDENTIALS.map((cred) => (
              <Button
                key={cred.email}
                type="link"
                size="small"
                onClick={() =>
                  handleQuickLogin(cred.email, cred.token, cred.role)
                }
                loading={loading}
                block
                style={{ marginBottom: '4px' }}
              >
                {cred.role}
              </Button>
            ))}
          </div>

          <Alert
            message="Available Tokens"
            description={
              <div style={{ fontSize: '11px', marginTop: '8px' }}>
                <div>admin: token_admin_abc123</div>
                <div>analyst: token_analyst_xyz789</div>
                <div>support: token_support_def456</div>
              </div>
            }
            type="warning"
            showIcon
            style={{ marginTop: '24px' }}
          />
        </Card>
      </Col>
    </Row>
  );
};
