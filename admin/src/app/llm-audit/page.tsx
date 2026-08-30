'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '@/lib/api';

interface LLMAuditRecord {
  event_id: string;
  user_id: string;
  model: string;
  prompt: string;
  response: string;
  tokens_used: number;
  latency_ms: number;
  cost_usd: number;
  created_at: string;
  status: string;
}

interface ModelStats {
  model: string;
  total_calls: number;
  total_tokens: number;
  avg_latency_ms: number;
  total_cost_usd: number;
}

export default function LLMAuditPage() {
  const [activeTab, setActiveTab] = useState<'recent' | 'models' | 'users'>('recent');
  const [recentCalls, setRecentCalls] = useState<LLMAuditRecord[]>([]);
  const [modelStats, setModelStats] = useState<ModelStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCall, setSelectedCall] = useState<LLMAuditRecord | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      if (activeTab === 'recent') {
        const res = await fetchAPI('/api/v1/admin/audit/recent?limit=50');
        if (res?.data) {
          setRecentCalls(res.data.calls || []);
        }
      } else if (activeTab === 'models') {
        const res = await fetchAPI('/api/v1/admin/audit/model-stats');
        if (res?.data) {
          setModelStats(res.data.models || []);
        }
      }
    } catch (err) {
      console.error('Failed to load LLM audit data:', err);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadData(), 0);
    return () => window.clearTimeout(timer);
  }, [loadData]);

  const formatDate = (dateStr: string) => {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleString('zh-CN');
  };

  const formatCost = (cost: number) => {
    return `$${(cost || 0).toFixed(6)}`;
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/llm-audit" />
      <main className="flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">LLM 审计看板</h1>
          <p className="text-gray-500 mt-1">追踪 AI 调用、Token 消耗与成本</p>
        </div>

        {/* 标签页 */}
        <div className="flex gap-2 mb-6">
          {[
            { key: 'recent', label: '最近调用' },
            { key: 'models', label: '模型统计' },
            { key: 'users', label: '用户用量' },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === tab.key
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-600 hover:bg-gray-100'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* 最近调用 */}
        {activeTab === 'recent' && (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">时间</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">用户</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">模型</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tokens</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">延迟</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">成本</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">操作</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-500">加载中...</td></tr>
                ) : recentCalls.length === 0 ? (
                  <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-500">暂无数据</td></tr>
                ) : (
                  recentCalls.map((call) => (
                    <tr key={call.event_id} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm text-gray-900">{formatDate(call.created_at)}</td>
                      <td className="px-4 py-3 text-sm text-gray-600 font-mono">{call.user_id?.slice(0, 12)}...</td>
                      <td className="px-4 py-3 text-sm">
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                          {call.model}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900">{call.tokens_used?.toLocaleString()}</td>
                      <td className="px-4 py-3 text-sm text-gray-600">{call.latency_ms}ms</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{formatCost(call.cost_usd)}</td>
                      <td className="px-4 py-3 text-sm">
                        <button
                          onClick={() => setSelectedCall(call)}
                          className="text-blue-600 hover:text-blue-800"
                        >
                          详情
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* 模型统计 */}
        {activeTab === 'models' && (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">模型</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">总调用次数</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">总Tokens</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">平均延迟</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">总成本</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-500">加载中...</td></tr>
                ) : modelStats.length === 0 ? (
                  <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-500">暂无数据</td></tr>
                ) : (
                  modelStats.map((stat) => (
                    <tr key={stat.model} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm font-medium text-gray-900">{stat.model}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{stat.total_calls?.toLocaleString()}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{stat.total_tokens?.toLocaleString()}</td>
                      <td className="px-4 py-3 text-sm text-gray-600">{Math.round(stat.avg_latency_ms)}ms</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{formatCost(stat.total_cost_usd)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* 用户用量 */}
        {activeTab === 'users' && (
          <div className="bg-white rounded-lg shadow p-8 text-center">
            <p className="text-gray-500">用户用量统计功能开发中...</p>
          </div>
        )}

        {/* 详情弹窗 */}
        {selectedCall && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-3xl w-full max-h-[80vh] overflow-auto">
              <div className="p-6 border-b border-gray-200 flex justify-between items-center">
                <h3 className="text-lg font-bold">调用详情</h3>
                <button
                  onClick={() => setSelectedCall(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ✕
                </button>
              </div>
              <div className="p-6 space-y-4">
                <div>
                  <label className="text-xs font-medium text-gray-500 uppercase">Event ID</label>
                  <p className="text-sm font-mono text-gray-900">{selectedCall.event_id}</p>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-500 uppercase">Prompt</label>
                  <pre className="mt-1 p-3 bg-gray-50 rounded text-sm text-gray-800 overflow-auto max-h-40">
                    {selectedCall.prompt || '(空)'}
                  </pre>
                </div>
                <div>
                  <label className="text-xs font-medium text-gray-500 uppercase">Response</label>
                  <pre className="mt-1 p-3 bg-gray-50 rounded text-sm text-gray-800 overflow-auto max-h-40">
                    {selectedCall.response || '(空)'}
                  </pre>
                </div>
                <div className="grid grid-cols-4 gap-4">
                  <div>
                    <label className="text-xs font-medium text-gray-500 uppercase">Tokens</label>
                    <p className="text-sm font-bold">{selectedCall.tokens_used}</p>
                  </div>
                  <div>
                    <label className="text-xs font-medium text-gray-500 uppercase">延迟</label>
                    <p className="text-sm font-bold">{selectedCall.latency_ms}ms</p>
                  </div>
                  <div>
                    <label className="text-xs font-medium text-gray-500 uppercase">成本</label>
                    <p className="text-sm font-bold">{formatCost(selectedCall.cost_usd)}</p>
                  </div>
                  <div>
                    <label className="text-xs font-medium text-gray-500 uppercase">状态</label>
                    <p className="text-sm font-bold">{selectedCall.status}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
