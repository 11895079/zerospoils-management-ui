import React from 'react';
import { Row, Col, Card, Skeleton, Empty, Button, Space } from 'antd';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { ReloadOutlined } from '@ant-design/icons';
import { useMetrics } from '../hooks/useMetrics';
import { MetricCard } from '../components/MetricCard';

export const Dashboard: React.FC = () => {
  const { current, history, loading, error, refetch } = useMetrics();

  if (error) {
    return (
      <Empty
        description="Failed to load metrics"
        style={{ marginTop: '50px' }}
      >
        <Button type="primary" onClick={refetch}>
          Try Again
        </Button>
      </Empty>
    );
  }

  const formatNumber = (num: number) => {
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  };

  return (
    <div>
      <Row
        justify="space-between"
        align="middle"
        style={{ marginBottom: '24px' }}
      >
        <h1>Launch & Operations Dashboard</h1>
        <Button
          icon={<ReloadOutlined />}
          onClick={refetch}
          loading={loading}
        >
          Refresh
        </Button>
      </Row>

      {/* Key Metrics Row */}
      {loading ? (
        <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
          {[...Array(4)].map((_, i) => (
            <Col key={i} xs={24} sm={12} lg={6}>
              <Card>
                <Skeleton active />
              </Card>
            </Col>
          ))}
        </Row>
      ) : current ? (
        <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="New Installs (24h)"
              value={current.newInstalls}
              color="#1890ff"
              format="number"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="Active Users"
              value={current.activeUsers}
              color="#52c41a"
              format="number"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="Crash-Free Rate"
              value={current.crashFreeRate}
              color="#faad14"
              format="percentage"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="D1 Retention"
              value={current.d1Retention}
              color="#722ed1"
              format="percentage"
            />
          </Col>
        </Row>
      ) : null}

      {/* Secondary Metrics Row */}
      {current && (
        <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="Avg Session Length"
              value={current.avgSessionLength}
              color="#13c2c2"
              format="duration"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="Items Added"
              value={current.itemsAdded}
              color="#eb2f96"
              format="number"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <MetricCard
              title="Notification Opt-In Rate"
              value={current.notificationOptInRate}
              color="#fa8c16"
              format="percentage"
            />
          </Col>
          <Col xs={24} sm={12} lg={6}>
            <Card style={{ borderTop: '4px solid #999' }}>
              <div style={{ fontSize: '12px', color: '#666' }}>Last Updated</div>
              <div style={{ fontSize: '14px', marginTop: '8px' }}>
                {new Date(current.timestamp).toLocaleTimeString()}
              </div>
            </Card>
          </Col>
        </Row>
      )}

      {/* Charts Row */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={24} lg={12}>
          <Card title="New Installs (24h)" loading={loading}>
            {history && history.length > 0 && (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={history}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="timestamp"
                    tick={{
                      fontSize: 12,
                    }}
                    tickFormatter={(value) =>
                      new Date(value).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })
                    }
                  />
                  <YAxis />
                  <Tooltip
                    labelFormatter={(value) =>
                      new Date(value).toLocaleString()
                    }
                  />
                  <Line
                    type="monotone"
                    dataKey="newInstalls"
                    stroke="#1890ff"
                    dot={false}
                    isAnimationActive={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card title="Key Metrics Comparison" loading={loading}>
            {history && history.length > 0 && (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={history.slice(-12)}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="timestamp"
                    tick={{
                      fontSize: 12,
                    }}
                    tickFormatter={(value) =>
                      new Date(value).toLocaleTimeString([], {
                        hour: '2-digit',
                      })
                    }
                  />
                  <YAxis />
                  <Tooltip
                    labelFormatter={(value) =>
                      new Date(value).toLocaleString()
                    }
                  />
                  <Legend />
                  <Bar
                    dataKey="activeUsers"
                    fill="#52c41a"
                    isAnimationActive={false}
                  />
                  <Bar
                    dataKey="itemsAdded"
                    fill="#eb2f96"
                    isAnimationActive={false}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </Card>
        </Col>
      </Row>

      {/* Retention & Crash Rate */}
      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Retention Trend" loading={loading}>
            {history && history.length > 0 && (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={history}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="timestamp"
                    tick={{
                      fontSize: 12,
                    }}
                    tickFormatter={(value) =>
                      new Date(value).toLocaleTimeString([], {
                        hour: '2-digit',
                      })
                    }
                  />
                  <YAxis
                    domain={[0, 1]}
                    tickFormatter={(value) =>
                      `${(value * 100).toFixed(0)}%`
                    }
                  />
                  <Tooltip
                    formatter={(value) => [
                      `${((value as number) * 100).toFixed(1)}%`,
                      'D1 Retention',
                    ]}
                    labelFormatter={(value) =>
                      new Date(value).toLocaleString()
                    }
                  />
                  <Line
                    type="monotone"
                    dataKey="d1Retention"
                    stroke="#722ed1"
                    dot={false}
                    isAnimationActive={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card title="Crash-Free Rate" loading={loading}>
            {history && history.length > 0 && (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={history}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="timestamp"
                    tick={{
                      fontSize: 12,
                    }}
                    tickFormatter={(value) =>
                      new Date(value).toLocaleTimeString([], {
                        hour: '2-digit',
                      })
                    }
                  />
                  <YAxis
                    domain={[0.95, 1]}
                    tickFormatter={(value) =>
                      `${(value * 100).toFixed(0)}%`
                    }
                  />
                  <Tooltip
                    formatter={(value) => [
                      `${((value as number) * 100).toFixed(1)}%`,
                      'Crash-Free Rate',
                    ]}
                    labelFormatter={(value) =>
                      new Date(value).toLocaleString()
                    }
                  />
                  <Line
                    type="monotone"
                    dataKey="crashFreeRate"
                    stroke="#faad14"
                    dot={false}
                    isAnimationActive={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
};
