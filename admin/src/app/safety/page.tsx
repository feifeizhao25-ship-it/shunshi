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

  const rules = [
    { id: 1, name: '敏感内容过滤', enabled: true, triggers: 156, description: '检测并过滤用户生成内容中的敏感词汇' },
    { id: 2, name: 'Prompt注入防护', enabled: true, triggers: 23, description: '防止恶意Prompt注入攻击AI模型' },
    { id: 3, name: '批量注册检测', enabled: true, triggers: 8, description: '检测并阻止批量注册行为' },
    { id: 4, name: '异常流量监控', enabled: true, triggers: 45, description: '监控API请求频率异常' },
    { id: 5, name: '数据泄露检测', enabled: false, triggers: 0, description: '检测敏感数据泄露风险' },
    { id: 6, name: 'IP信誉检查', enabled: true, triggers: 12, description: '检查请求IP的信誉评分' },
  ];

  return (
    <div className="flex">
      <Sidebar active="/safety" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">安全中心</h2>

        {/* Safety Score */}
        <div className="bg-white rounded-xl border border-gray-200 p-6 mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold text-gray-800">安全评分</h3>
              <p className="text-sm text-gray-400 mt-1">基于安全事件和防护规则的综合评估</p>
            </div>
            <div className="text-5xl font-bold text-green-600">87</div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-4 mb-6 border-b border-gray-200">
          <button onClick={() => setTab('events')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'events' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500'}`}>安全事件</button>
          <button onClick={() => setTab('rules')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'rules' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500'}`}>防护规则</button>
        </div>

        {tab === 'events' && (
          <div className="space-y-3">
            {loading ? (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-400">加载中...</div>
            ) : events.length === 0 ? (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-400">暂无安全事件</div>
            ) : (
              events.map((e) => (
                <div key={e.id} className="bg-white rounded-xl border border-gray-200 p-5">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-4">
                      <span className={`px-2.5 py-1 rounded text-xs font-medium ${severityColors[e.severity]}`}>{e.severity.toUpperCase()}</span>
                      <div>
                        <div className="font-medium text-gray-800">{e.type}</div>
                        <div className="text-sm text-gray-600 mt-1">{e.description}</div>
                        <div className="flex gap-4 mt-2 text-xs text-gray-400">
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
          <div className="space-y-3">
            {rules.map((rule) => (
              <div key={rule.id} className="bg-white rounded-xl border border-gray-200 p-5 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-3">
                    <span className="font-medium text-gray-800">{rule.name}</span>
                    <span className={`text-xs px-2 py-0.5 rounded ${rule.enabled ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {rule.enabled ? '启用' : '禁用'}
                    </span>
                  </div>
                  <p className="text-sm text-gray-500 mt-1">{rule.description}</p>
                </div>
                <div className="text-sm text-gray-400">{rule.triggers} 次触发</div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
