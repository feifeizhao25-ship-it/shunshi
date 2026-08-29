'use client';

import { useState, useEffect } from 'react';
import Sidebar from './sidebar';
import { fetchAPI } from '../lib/api';

interface DashboardStats {
  total_users: number;
  total_content: number;
  safety_events: number;
  active_alerts: number;
  active_subscriptions: number;
  ai_requests_today: number;
  new_users_today: number;
  content_published_today: number;
}

interface Alert {
  id: number;
  type: string;
  message: string;
  time: string;
  level: string;
  resolved: boolean;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  useEffect(() => {
    async function loadData() {
      setLoading(true);
      setLoadError(false);
      try {
        const [statsRes, alertsRes] = await Promise.all([
          fetchAPI('/api/v1/admin/dashboard'),
          fetchAPI('/api/v1/alerts?limit=5&resolved=false'),
        ]);
        if (statsRes?.data) setStats(statsRes.data as DashboardStats);
        if (alertsRes?.data) setAlerts(alertsRes.data as Alert[]);
      } catch {
        setLoadError(true);
      }
      setLoading(false);
    }
    loadData();
  }, []);

  const statCards = stats ? [
    { label: '总用户数', value: stats.total_users?.toLocaleString() || '0', change: `+${stats.new_users_today || 0} 今日`, color: 'bg-blue-500' },
    { label: '内容总数', value: stats.total_content?.toLocaleString() || '0', change: `+${stats.content_published_today || 0} 今日`, color: 'bg-green-500' },
    { label: '安全事件', value: String(stats.safety_events ?? 0), change: '近7天', color: 'bg-orange-500' },
    { label: '活跃告警', value: String(stats.active_alerts ?? 0), change: '需处理', color: 'bg-red-500' },
    { label: '付费订阅', value: stats.active_subscriptions?.toLocaleString() || '0', change: '活跃', color: 'bg-purple-500' },
    { label: 'AI请求/日', value: stats.ai_requests_today?.toLocaleString() || '0', change: '今日', color: 'bg-indigo-500' },
  ] : [
    { label: '总用户数', value: '-', change: '加载中...', color: 'bg-blue-500' },
    { label: '内容总数', value: '-', change: '', color: 'bg-green-500' },
    { label: '安全事件', value: '-', change: '', color: 'bg-orange-500' },
    { label: '活跃告警', value: '-', change: '', color: 'bg-red-500' },
    { label: '付费订阅', value: '-', change: '', color: 'bg-purple-500' },
    { label: 'AI请求/日', value: '-', change: '', color: 'bg-indigo-500' },
  ];

  const levelStyles: Record<string, string> = {
    critical: 'bg-red-100 text-red-700',
    high: 'bg-red-100 text-red-700',
    medium: 'bg-orange-100 text-orange-700',
    low: 'bg-yellow-100 text-yellow-700',
    info: 'bg-blue-100 text-blue-700',
  };

  return (
    <div className="flex">
      <Sidebar active="/" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">仪表盘</h2>
          <span className="text-sm text-gray-400">
            {new Date().toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}
          </span>
        </div>

        {loading && (
          <div className="mb-4 px-4 py-2 bg-blue-50 text-blue-600 text-sm rounded-lg">
            正在连接后端 API...
          </div>
        )}
        {loadError && (
          <div className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg" role="alert">
            运营数据读取失败，当前未展示推测值或示例数据。请检查后端服务后重试。
          </div>
        )}

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 mb-8">
          {statCards.map((stat) => (
            <div key={stat.label} className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition-shadow">
              <div className="flex items-center gap-3 mb-3">
                <div className={`w-2 h-8 rounded ${stat.color}`} />
                <span className="text-sm text-gray-500">{stat.label}</span>
              </div>
              <div className="text-3xl font-bold text-gray-900">{stat.value}</div>
              <div className="text-sm text-gray-400 mt-1">{stat.change}</div>
            </div>
          ))}
        </div>

        {/* Recent Alerts */}
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="font-semibold text-gray-800">最近告警</h3>
            <a href="/alerts" className="text-sm text-blue-600 hover:underline">查看全部</a>
          </div>
          {alerts.length > 0 ? (
            <div className="divide-y divide-gray-100">
              {alerts.map((alert, i) => (
                <div key={alert.id || i} className="flex items-center justify-between px-6 py-4">
                  <div className="flex items-center gap-4">
                    <span className={`px-2.5 py-1 rounded text-xs font-medium ${levelStyles[alert.level] || 'bg-gray-100 text-gray-700'}`}>
                      {alert.type}
                    </span>
                    <span className="text-sm text-gray-700">{alert.message}</span>
                  </div>
                  <span className="text-xs text-gray-400 whitespace-nowrap ml-4">{alert.time}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="px-6 py-8 text-center text-gray-400 text-sm">
              {loading ? '加载中...' : loadError ? '告警数据暂时无法读取' : '暂无活跃告警'}
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {[
            { label: '用户管理', href: '/users', desc: '查看和管理用户', icon: '👥' },
            { label: '内容审核', href: '/content', desc: '审核和管理内容', icon: '📝' },
            { label: '安全中心', href: '/safety', desc: '安全事件和风险', icon: '🛡️' },
            { label: '知识库', href: '/rag', desc: 'RAG知识库管理', icon: '📚' },
          ].map((action) => (
            <a key={action.href} href={action.href} className="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md hover:border-blue-300 transition-all">
              <div className="text-2xl mb-2">{action.icon}</div>
              <div className="font-medium text-gray-800">{action.label}</div>
              <div className="text-xs text-gray-400 mt-1">{action.desc}</div>
            </a>
          ))}
        </div>
      </main>
    </div>
  );
}
