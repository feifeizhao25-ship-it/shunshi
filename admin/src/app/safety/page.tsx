'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface SafetyEvent {
  id: string;
  type: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  user_id?: string;
  content_id?: string;
  detected_at: string;
  action_taken: string;
  resolved: boolean;
}

export default function SafetyPage() {
  const [events, setEvents] = useState<SafetyEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'events' | 'rules'>('events');

  useEffect(() => { loadEvents(); }, []);

  async function loadEvents() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: SafetyEvent[] }>('/api/v1/safety/events?limit=50');
      if (res?.data) setEvents(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const severityColors: Record<string, string> = {
    critical: 'bg-red-100 text-red-700', high: 'bg-orange-100 text-orange-700',
    medium: 'bg-yellow-100 text-yellow-700', low: 'bg-blue-100 text-blue-700',
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/safety" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">安全中心</h2>

        {/* Safety Score */}
        <div className="bg-white rounded-xl border border-gray-200 p-6 mb-8">
          <h3 className="text-lg font-semibold text-gray-800">安全事件</h3>
          <p className="text-sm text-gray-600 mt-1">只展示接口返回的事件。这里不显示综合评分，也不在页面上改动安全开关。</p>
        </div>

        {/* Tabs */}
        <div className="flex gap-4 mb-6 border-b border-gray-200">
          <button onClick={() => setTab('events')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'events' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500'}`}>安全事件</button>
          <button onClick={() => setTab('rules')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'rules' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500'}`}>防护规则</button>
        </div>

        {tab === 'events' && (
          <div className="space-y-3">
            {loading ? (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-600">加载中...</div>
            ) : events.length === 0 ? (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-600">暂无安全事件</div>
            ) : (
              events.map((e) => (
                <div key={e.id} className="bg-white rounded-xl border border-gray-200 p-5">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4">
                      <span className={`px-2.5 py-1 rounded text-xs font-medium ${severityColors[e.severity]}`}>{{ critical: '严重', high: '高', medium: '中', low: '低' }[e.severity] || e.severity}</span>
                      <div>
                        <div className="font-medium text-gray-800">{e.type}</div>
                        <div className="text-sm text-gray-600 mt-1">{e.description}</div>
                        <div className="flex gap-4 mt-2 text-xs text-gray-600">
                          {e.user_id && <span>用户: {e.user_id.slice(0, 8)}</span>}
                          <span>{new Date(e.detected_at).toLocaleString('zh-CN')}</span>
                          <span>处理: {e.action_taken}</span>
                        </div>
                      </div>
                    </div>
                    <span className={`text-xs ${e.resolved ? 'text-green-600' : 'text-orange-600'}`}>
                      {e.resolved ? '已处理' : '待处理'}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {tab === 'rules' && (
          <div className="bg-white rounded-xl border border-gray-200 p-6 text-sm text-gray-700 leading-6">
            防护规则由服务端配置。当前接口没有返回规则状态和触发次数，这里不展示估计数字，也不提供开关。
          </div>
        )}
      </main>
    </div>
  );
}
