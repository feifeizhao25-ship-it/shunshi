'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, putAPI } from '../../lib/api';

interface Prompt {
  id: string;
  name: string;
  description: string;
  template: string;
  version: number;
  category: string;
  is_active: boolean;
  usage_count: number;
  avg_latency_ms: number;
  updated_at: string;
}

export default function PromptsPage() {
  const [prompts, setPrompts] = useState<Prompt[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPrompt, setSelectedPrompt] = useState<Prompt | null>(null);
  const [filterCategory, setFilterCategory] = useState('all');

  useEffect(() => { loadPrompts(); }, []);

  async function loadPrompts() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: Prompt[] }>('/api/v1/prompts?limit=100');
      if (res?.data) setPrompts(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const categories = ['all', ...new Set(prompts.map((p) => p.category))];
  const filteredPrompts = filterCategory === 'all' ? prompts : prompts.filter((p) => p.category === filterCategory);

  return (
    <div className="flex">
      <Sidebar active="/prompts" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">Prompt 管理</h2>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">+ 新建Prompt</button>
        </div>

        <div className="flex gap-2 mb-6">
          {categories.map((c) => (
            <button key={c} onClick={() => setFilterCategory(c)}
              className={`px-3 py-2 rounded-lg text-sm ${filterCategory === c ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600'}`}>
              {c === 'all' ? '全部' : c}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-3 gap-6">
          {/* Prompt List */}
          <div className="col-span-1 space-y-2 max-h-[80vh] overflow-y-auto">
            {loading ? (
              <div className="text-center text-gray-400 py-12">加载中...</div>
            ) : filteredPrompts.length === 0 ? (
              <div className="text-center text-gray-400 py-12">暂无Prompt</div>
            ) : (
              filteredPrompts.map((p) => (
                <div key={p.id} onClick={() => setSelectedPrompt(p)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all ${selectedPrompt?.id === p.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white hover:border-gray-300'}`}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-sm text-gray-800">{p.name}</span>
                    <span className={`text-xs px-2 py-0.5 rounded ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {p.is_active ? '启用' : '禁用'}
                    </span>
                  </div>
                  <div className="text-xs text-gray-400">{p.category} · v{p.version} · 使用 {p.usage_count} 次</div>
                </div>
              ))
            )}
          </div>

          {/* Prompt Detail */}
          <div className="col-span-2">
            {selectedPrompt ? (
              <div className="bg-white rounded-xl border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-gray-800">{selectedPrompt.name}</h3>
                  <span className="text-xs text-gray-400">v{selectedPrompt.version}</span>
                </div>
                <p className="text-sm text-gray-500 mb-4">{selectedPrompt.description}</p>
                <div className="mb-4">
                  <label className="text-sm font-medium text-gray-600 mb-2 block">模板内容</label>
                  <pre className="bg-gray-900 text-green-400 p-4 rounded-lg text-sm whitespace-pre-wrap overflow-x-auto font-mono">
                    {selectedPrompt.template}
                  </pre>
                </div>
                <div className="flex gap-6 text-sm text-gray-400">
                  <span>使用次数: {selectedPrompt.usage_count}</span>
                  <span>平均延迟: {selectedPrompt.avg_latency_ms}ms</span>
                  <span>更新: {selectedPrompt.updated_at ? new Date(selectedPrompt.updated_at).toLocaleDateString('zh-CN') : '-'}</span>
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-400">
                选择左侧的Prompt查看详情
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
