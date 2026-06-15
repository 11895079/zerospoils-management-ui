import React from 'react';
import { Card } from 'antd';
import RemoteConfigManager from '../components/RemoteConfigManager';

export const RemoteConfig: React.FC = () => {
  return (
    <Card>
      <RemoteConfigManager />
    </Card>
  );
};
