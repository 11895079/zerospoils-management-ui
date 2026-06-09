import React, { useState, useEffect } from 'react';
import { Layout, Menu, Button, Dropdown, Space, Popover, Alert } from 'antd';
import {
  BarChartOutlined,
  MessageOutlined,
  LineChartOutlined,
  SettingOutlined,
  LogoutOutlined,
  HealthCheckOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
} from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';
import { api } from '../utils/api';
import type { HealthStatus } from '../types';

const { Header, Sider, Content } = Layout;

interface MainLayoutProps {
  children: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  const [collapsed, setCollapsed] = useState(false);
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const res = await api.getHealth();
        setHealth(res.data);
      } catch (err) {
        console.error('Health check failed:', err);
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 30000); // Check every 30s
    return () => clearInterval(interval);
  }, []);

  const handleLogout = () => {
    api.clearToken();
    localStorage.removeItem('user_role');
    navigate('/login');
  };

  const userMenuItems = [
    {
      key: 'profile',
      label: 'Profile',
      onClick: () => navigate('/settings'),
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      label: 'Logout',
      icon: <LogoutOutlined />,
      onClick: handleLogout,
    },
  ];

  const healthColor =
    health?.status === 'healthy'
      ? '#52c41a'
      : health?.status === 'degraded'
        ? '#faad14'
        : '#f5222d';

  const healthContent = health && (
    <div style={{ width: '300px' }}>
      <div style={{ marginBottom: '12px', fontWeight: 'bold' }}>
        System Health
      </div>
      <div style={{ fontSize: '12px' }}>
        <div>API: {health.services.api.status}</div>
        <div>Worker: {health.services.worker.status}</div>
        <div>DuckDB: {health.services.duckdb.status}</div>
        <div style={{ marginTop: '8px', color: '#666' }}>
          Uptime: {Math.floor(health.uptime / 3600)}h
        </div>
      </div>
    </div>
  );

  const menuItems = [
    {
      key: '/dashboard',
      icon: <BarChartOutlined />,
      label: 'Dashboard',
      onClick: () => navigate('/dashboard'),
    },
    {
      key: '/feedback',
      icon: <MessageOutlined />,
      label: 'Feedback',
      onClick: () => navigate('/feedback'),
    },
    {
      key: '/telemetry',
      icon: <LineChartOutlined />,
      label: 'Telemetry',
      onClick: () => navigate('/telemetry'),
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: 'Settings',
      onClick: () => navigate('/settings'),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={200}
        style={{
          background: '#001529',
        }}
      >
        <div
          style={{
            height: '64px',
            background: '#001529',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#fff',
            fontSize: '18px',
            fontWeight: 'bold',
            paddingLeft: collapsed ? '0' : '16px',
          }}
        >
          {!collapsed && '🍽️ ZeroSpoils Ops'}
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
        />
      </Sider>

      <Layout>
        <Header
          style={{
            background: '#fff',
            padding: '0 24px',
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
            style={{ fontSize: '18px' }}
          />

          <Space size="large">
            {health && (
              <Popover
                content={healthContent}
                title="System Status"
                placement="bottomRight"
              >
                <Button
                  type="text"
                  icon={<HealthCheckOutlined />}
                  style={{ color: healthColor, fontSize: '16px' }}
                  title={`Status: ${health.status}`}
                />
              </Popover>
            )}

            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
              <Button type="text">👤</Button>
            </Dropdown>
          </Space>
        </Header>

        <Content
          style={{
            margin: '24px 16px',
            padding: '24px',
            background: '#f5f5f5',
            borderRadius: '8px',
            minHeight: 'calc(100vh - 112px)',
          }}
        >
          {health?.status === 'degraded' && (
            <Alert
              message="System Status: Degraded"
              description="Some services may be running slower than usual"
              type="warning"
              closable
              style={{ marginBottom: '24px' }}
            />
          )}
          {health?.status === 'unhealthy' && (
            <Alert
              message="System Status: Unhealthy"
              description="Some services are not responding. Check the status page."
              type="error"
              closable
              style={{ marginBottom: '24px' }}
            />
          )}
          {children}
        </Content>
      </Layout>
    </Layout>
  );
};
