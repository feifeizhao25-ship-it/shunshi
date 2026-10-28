'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

export default function AnalyticsPage() {
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);
  const [period, setPeriod] = useState('7d');
  const [metrics, setMetrics] = useState({
    totalUsers: 0,
    dau: 0,
    avgSessionDuration: 0,
    retention7d: 0,
    aiRequestTotal: 0,
    aiRequestSuccess: 0,
    revenue: 0,
    arpu: 0,
  });

  const loadAnalytics = useCallback(async () => {
    setLoading(true);
    setLoadError(false);
    try {
      const res = await fetchAPI<{ data?: Record<string, number>; error?: unknown }>(`/api/v1/data-analytics/overview?period=${period}`);
      if (res?.data && !res.error && !Array.isArray(res.data)) {
        const d = res.data;
        setMetrics({
          totalUsers: d.total_users || 0,
          dau: d.dau || 0,
          avgSessionDuration: d.avg_session_duration || 0,
          retention7d: d.retention_7d || 0,
          aiRequestTotal: d.ai_request_total || 0,
          aiRequestSuccess: d.ai_request_success || 0,
          revenue: d.revenue || 0,
          arpu: d.arpu || 0,
        });
      } else {
        setLoadError(true);
      }
    } catch {
      setLoadError(true);
    }
    setLoading(false);
  }, [period]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadAnalytics(), 0);
    return () => window.clearTimeout(timer);
  }, [loadAnalytics]);

  const periods = [
    { value: '24h', label: '24小时' },
    { value: '7d', label: '7天' },
    { value: '30d', label: '30天' },
    { value: '90d', label: '90天' },
  ];

  const kpiCards = [
    { label: '总用户', value: loadError ? '—' : metrics.totalUsers.toLocaleString('zh-CN'), icon: '👥', sub: '' },
    { label: '日活跃', value: loadError ? '—' : metrics.dau.toLocaleString('zh-CN'), icon: '📱', sub: '' },
    { label: '7日留存', value: loadError ? '—' : `${(metrics.retention7d * 100).toFixed(1)}%`, icon: '🔄', sub: '' },
    { label: '平均会话', value: loadError ? '—' : `${metrics.avgSessionDuration}分钟`, icon: '⏱', sub: '' },
    { label: 'AI总请求', value: loadError ? '—' : metrics.aiRequestTotal.toLocaleString('zh-CN'), icon: '🤖', sub: loadError ? '' : `成功率 ${metrics.aiRequestTotal > 0 ? ((metrics.aiRequestSuccess / metrics.aiRequestTotal) * 100).toFixed(1) : 0}%` },
    { label: '总收入', value: loadError ? '—' : `¥${metrics.revenue.toLocaleString('zh-CN')}`, icon: '💰', sub: loadError ? '' : `人均 ¥${metrics.arpu.toFixed(2)}` },
  ];

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/analytics" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
          <h2 className="text-2xl font-bold text-gray-800">数据分析</h2>
          <div className="flex flex-wrap gap-2">
            {periods.map((p) => (
              <button key={p.value} onClick={() => setPeriod(p.value)}
                className={`px-4 py-2 rounded-lg text-sm ${period === p.value ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {/* KPI Cards */}
        {loading && <div className="mb-4 px-4 py-2 bg-blue-50 text-blue-700 text-sm rounded-lg">正在读取运营概览...</div>}
        {loadError && (
          <div role="alert" className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg">
            运营概览暂时读不到。下面不展示功能使用率、地区分布或接口耗时的估计值。
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 mb-8">
          {kpiCards.map((kpi) => (
            <div key={kpi.label} className="bg-white rounded-xl border border-gray-200 p-6">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-lg">{kpi.icon}</span>
                <span className="text-sm text-gray-500">{kpi.label}</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{kpi.value}</div>
              {kpi.sub && <div className="text-xs text-gray-600 mt-1">{kpi.sub}</div>}
            </div>
          ))}
        </div>

      </main>
    </div>
  );
}
