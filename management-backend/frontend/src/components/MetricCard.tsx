import React from 'react';
import { Card, Row, Col, Statistic } from 'antd';
import {
  ArrowUpOutlined,
  ArrowDownOutlined,
  UserOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons';

interface MetricCardProps {
  title: string;
  value: number | string;
  icon?: React.ReactNode;
  trend?: number;
  trendLabel?: string;
  format?: 'number' | 'percentage' | 'duration';
  color?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  icon,
  trend,
  trendLabel,
  format,
  color,
}) => {
  const getTrendIcon = () => {
    if (trend === undefined) return null;
    return trend >= 0 ? (
      <ArrowUpOutlined style={{ color: '#52c41a' }} />
    ) : (
      <ArrowDownOutlined style={{ color: '#f5222d' }} />
    );
  };

  const formatValue = () => {
    if (format === 'percentage') {
      return typeof value === 'number'
        ? `${(value * 100).toFixed(1)}%`
        : value;
    }
    if (format === 'duration') {
      return typeof value === 'number' ? `${Math.round(value)}s` : value;
    }
    return typeof value === 'number' ? value.toLocaleString() : value;
  };

  return (
    <Card
      hoverable
      style={{
        borderTop: `4px solid ${color || '#1890ff'}`,
        borderRadius: '8px',
      }}
    >
      <Row align="middle" justify="space-between">
        <Col span={16}>
          <Statistic
            title={title}
            value={formatValue()}
            prefix={icon}
            valueStyle={{ fontSize: '24px', fontWeight: 'bold' }}
          />
          {trend !== undefined && (
            <div style={{ marginTop: '8px', fontSize: '12px' }}>
              {getTrendIcon()} {Math.abs(trend).toFixed(1)}% {trendLabel || 'vs last period'}
            </div>
          )}
        </Col>
      </Row>
    </Card>
  );
};
