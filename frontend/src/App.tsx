import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, theme } from 'antd';
import enUS from 'antd/locale/en_US';
import { MainLayout } from './layouts/MainLayout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { RemoteConfig } from './pages/RemoteConfig';
import { api } from './utils/api';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const token = api.getToken();
  return token ? <>{children}</> : <Navigate to="/login" replace />;
};

function App() {
  return (
    <ConfigProvider
      theme={{
        algorithm: theme.defaultAlgorithm,
        token: {
          colorPrimary: '#1890ff',
          colorSuccess: '#52c41a',
          colorWarning: '#faad14',
          colorError: '#ff4d4f',
          borderRadius: 8,
        },
      }}
      locale={enUS}
    >
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <MainLayout>
                  <Dashboard />
                </MainLayout>
              </ProtectedRoute>
            }
          />
          <Route
            path="/remote-config"
            element={
              <ProtectedRoute>
                <MainLayout>
                  <RemoteConfig />
                </MainLayout>
              </ProtectedRoute>
            }
          />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </ConfigProvider>
  );
}

export default App;
