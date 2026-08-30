'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, postAPI } from '../../lib/api';

interface Alert {
  id: string;
  type: string;
  message: string;
  level: 'critical' | 'high' | 'medium' | 'low' | 'info';
  source: string;
  created_at: string;
  resolved: boolean;
  resolved_by?: string;
  resolved_at?: string;
}

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterLevel, setFilterLevel] = useState('all');
  const [filterResolved, setFilterResolved] = useState('unresolved');

  const loadAlerts = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ limit: '100' });
      if (filterLevel !== 'all') params.set('level', filterLevel);
      if (filterResolved !== 'all') params.set('resolved', filterResolved === 'resolved' ? 'true' : 'false');
      const res = await fetchAPI<{ data: Alert[] }>(`/api/v1/alerts?${params}`);
      if (res?.data) setAlerts(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }, [filterLevel, filterResolved]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadAlerts(), 0);
    return () => window.clearTimeout(timer);
  }, [loadAlerts]);

  async function handleResolve(id: string) {
    try {
      await postAPI(`/api/v1/alerts/${id}/resolve`, {});
      loadAlerts();
    } catch { alert('操作失败'); }
  }

  const levelColors: Record<string, string> = {
    critical: 'bg-red-100 text-red-700 border-red-200',
    high: 'bg-orange-100 text-orange-700 border-orange-200',
    medium: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    low: 'bg-blue-100 text-blue-700 border-blue-200',
    info: 'bg-gray-100 text-gray-600 border-gray-200',
  };

  const levelCounts = alerts.reduce((acc, a) => { acc[a.level] = (acc[a.level] || 0) + 1; return acc; }, {} as Record<string, number>);

  return (
    <div className="flex">
      <Sidebar active="/alerts" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">告警管理</h2>
          <button onClick={loadAlerts} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">刷新</button>
        </div>

        {/* Level Summary */}
        <div className="grid grid-cols-5 gap-4 mb-6">
          {['critical', 'high', 'medium', 'low', 'info'].map((level) => (
            <div key={level} onClick={() => setFilterLevel(filterLevel === level ? 'all' : level)}
              className={`p-4 rounded-xl border cursor-pointer transition-all ${filterLevel === level ? 'ring-2 ring-blue-500' : ''} ${levelColors[level]}`}>
              <div className="text-sm font-medium capitalize">{level}</div>
              <div className="text-2xl font-bold mt-1">{levelCounts[level] || 0}</div>
            </div>
          ))}
        </div>

        {/* Filter */}
        <div className="flex gap-2 mb-6">
          {['unresolved', 'resolved', 'all'].map((f) => (
            <button key={f} onClick={() => setFilterResolved(f)}
              className={`px-3 py-2 rounded-lg text-sm ${filterResolved === f ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600'}`}>
              {{ unresolved: '未解决', resolved: '已解决', all: '全部' }[f]}
            </button>
          ))}
        </div>

        {/* Alerts List */}
        <div className="space-y-3">
          {loading ? (
            <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-400">加载中...</div>
          ) : alerts.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-400">暂无告警</div>
          ) : (
            alerts.map((alert) => (
              <div key={alert.id} className={`bg-white rounded-xl border p-5 ${alert.resolved ? 'opacity-60' : ''}`}>
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4">
                    <span className={`px-2.5 py-1 rounded text-xs font-medium mt-0.5 ${levelColors[alert.level]}`}>
                      {alert.level.toUpperCase()}
                    </span>
                    <div>
                      <div className="font-medium text-gray-800">{alert.type}</div>
                      <div className="text-sm text-gray-600 mt-1">{alert.message}</div>
                      <div className="flex gap-4 mt-2 text-xs text-gray-400">
                        <span>来源: {alert.source}</span>
                        <span>{new Date(alert.created_at).toLocaleString('zh-CN')}</span>
                        {alert.resolved_by && <span>处理人: {alert.resolved_by}</span>}
                      </div>
                    </div>
                  </div>
                  {!alert.resolved && (
                    <button onClick={() => handleResolve(alert.id)}
                      className="px-3 py-1.5 bg-green-50 text-green-600 text-sm rounded-lg hover:bg-green-100">
                      标记已解决
                    </button>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
