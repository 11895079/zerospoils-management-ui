import { useState, useEffect } from 'react';
import { api } from '../utils/api';
import type { MetricsSnapshot } from '../types';

interface UseMetricsReturn {
  current: MetricsSnapshot | null;
  history: MetricsSnapshot[];
  loading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
}

export function useMetrics(): UseMetricsReturn {
  const [current, setCurrent] = useState<MetricsSnapshot | null>(null);
  const [history, setHistory] = useState<MetricsSnapshot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchMetrics = async () => {
    try {
      setLoading(true);
      const [currentRes, historyRes] = await Promise.all([
        api.getCurrentMetrics(),
        api.getMetricsHistory(24),
      ]);
      setCurrent(currentRes.data.data);
      setHistory(historyRes.data.data);
      setError(null);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMetrics();
    const interval = setInterval(fetchMetrics, 30000); // Refresh every 30s
    return () => clearInterval(interval);
  }, []);

  return { current, history, loading, error, refetch: fetchMetrics };
}
