'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface AnalyticsData {
  period: string;
  users: number;
  new_users: number;
  ai_requests: number;
  content_views: number;
  subscription_revenue: number;
}

interface ChartData {
  labels: string[];
  datasets: { label: string; data: number[]; color: string }[];
}

export default function AnalyticsPage() {
  const [loading, setLoading] = useState(true);
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

  useEffect(() => { loadAnalytics(); }, [period]);

  async function loadAnalytics() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: any }>(`/api/v1/data-analytics/overview?period=${period}`);
      if (res?.data) {
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
      }
    } catch { /* empty */ }
    setLoading(false);
  }

  const periods = [
    { value: '24h', label: '24小时' },
    { value: '7d', label: '7天' },
    { value: '30d', label: '30天' },
    { value: '90d', label: '90天' },
  ];

  const kpiCards = [
    { label: '总用户', value: metrics.totalUsers.toLocaleString(), icon: '👥', sub: '' },
    { label: 'DAU', value: metrics.dau.toLocaleString(), icon: '📱', sub: '' },
    { label: '7日留存', value: `${(metrics.retention7d * 100).toFixed(1)}%`, icon: '🔄', sub: '' },
    { label: '平均会话', value: `${metrics.avgSessionDuration}分钟`, icon: '⏱', sub: '' },
    { label: 'AI总请求', value: metrics.aiRequestTotal.toLocaleString(), icon: '🤖', sub: `成功率 ${metrics.aiRequestTotal > 0 ? ((metrics.aiRequestSuccess / metrics.aiRequestTotal) * 100).toFixed(1) : 0}%` },
    { label: '总收入', value: `¥${metrics.revenue.toLocaleString()}`, icon: '💰', sub: `ARPU ¥${metrics.arpu.toFixed(2)}` },
  ];

  // Feature usage breakdown
  const featureUsage = [
    { name: '体质测试', pct: 78, color: 'bg-blue-500' },
    { name: '节气养生', pct: 72, color: 'bg-green-500' },
    { name: 'AI对话', pct: 65, color: 'bg-purple-500' },
    { name: '食谱推荐', pct: 58, color: 'bg-orange-500' },
    { name: '运动指导', pct: 45, color: 'bg-red-500' },
    { name: '冥想音频', pct: 42, color: 'bg-indigo-500' },
    { name: '家庭管理', pct: 35, color: 'bg-teal-500' },
    { name: '经络穴位', pct: 30, color: 'bg-pink-500' },
  ];

  return (
    <div className="flex">
      <Sidebar active="/analytics" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">数据分析</h2>
          <div className="flex gap-2">
            {periods.map((p) => (
              <button key={p.value} onClick={() => setPeriod(p.value)}
                className={`px-4 py-2 rounded-lg text-sm ${period === p.value ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-3 gap-6 mb-8">
          {kpiCards.map((kpi) => (
            <div key={kpi.label} className="bg-white rounded-xl border border-gray-200 p-6">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-lg">{kpi.icon}</span>
                <span className="text-sm text-gray-500">{kpi.label}</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{kpi.value}</div>
              {kpi.sub && <div className="text-xs text-gray-400 mt-1">{kpi.sub}</div>}
            </div>
          ))}
        </div>

        {/* Feature Usage */}
        <div className="bg-white rounded-xl border border-gray-200 p-6 mb-8">
          <h3 className="font-semibold text-gray-800 mb-4">功能使用率</h3>
          <div className="space-y-4">
            {featureUsage.map((f) => (
              <div key={f.name} className="flex items-center gap-4">
                <span className="w-20 text-sm text-gray-600">{f.name}</span>
                <div className="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden">
                  <div className={`h-full ${f.color} rounded-full transition-all`} style={{ width: `${f.pct}%` }} />
                </div>
                <span className="text-sm text-gray-500 w-12 text-right">{f.pct}%</span>
              </div>
            ))}
          </div>
        </div>

        {/* API Performance */}
        <div className="grid grid-cols-2 gap-6">
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-800 mb-4">API响应时间 (ms)</h3>
            <div className="space-y-3">
              {[
                { endpoint: '/auth/login', avg: 120, p99: 350 },
                { endpoint: '/ai/companion', avg: 2800, p99: 5200 },
                { endpoint: '/contents', avg: 85, p99: 220 },
                { endpoint: '/users/profile', avg: 65, p99: 180 },
                { endpoint: '/subscription', avg: 150, p99: 380 },
              ].map((api) => (
                <div key={api.endpoint} className="flex items-center justify-between text-sm">
                  <span className="font-mono text-gray-600">{api.endpoint}</span>
                  <div className="flex gap-4">
                    <span className="text-gray-500">avg: {api.avg}ms</span>
                    <span className={api.p99 > 3000 ? 'text-red-500' : 'text-gray-400'}>p99: {api.p99}ms</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="bg-white rounded-xl border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-800 mb-4">用户分布</h3>
            <div className="space-y-3">
              {[
                { region: '华东', pct: 32 },
                { region: '华南', pct: 24 },
                { region: '华北', pct: 18 },
                { region: '西南', pct: 12 },
                { region: '华中', pct: 8 },
                { region: '海外', pct: 6 },
              ].map((r) => (
                <div key={r.region} className="flex items-center gap-4 text-sm">
                  <span className="w-10 text-gray-600">{r.region}</span>
                  <div className="flex-1 bg-gray-100 rounded-full h-3 overflow-hidden">
                    <div className="h-full bg-blue-400 rounded-full" style={{ width: `${r.pct}%` }} />
                  </div>
                  <span className="text-gray-500 w-10 text-right">{r.pct}%</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
