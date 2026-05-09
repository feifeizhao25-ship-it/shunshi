'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface AIModel {
  id: string;
  name: string;
  provider: string;
  type: string;
  context_window: number;
  is_active: boolean;
  avg_latency_ms: number;
  total_requests: number;
  success_rate: number;
  cost_per_1k: number;
}

export default function ModelsPage() {
  const [models, setModels] = useState<AIModel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadModels(); }, []);

  async function loadModels() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: AIModel[] }>('/api/v1/admin/config/ai-models');
      if (res?.data) setModels(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const defaultModels: AIModel[] = [
    { id: '1', name: 'GPT-4o', provider: 'OpenAI', type: 'chat', context_window: 128000, is_active: true, avg_latency_ms: 1800, total_requests: 45000, success_rate: 99.2, cost_per_1k: 0.005 },
    { id: '2', name: 'GPT-4o-mini', provider: 'OpenAI', type: 'chat', context_window: 128000, is_active: true, avg_latency_ms: 800, total_requests: 120000, success_rate: 99.5, cost_per_1k: 0.00015 },
    { id: '3', name: 'Claude-3.5-Sonnet', provider: 'Anthropic', type: 'chat', context_window: 200000, is_active: true, avg_latency_ms: 1500, total_requests: 30000, success_rate: 99.8, cost_per_1k: 0.003 },
    { id: '4', name: 'Qwen-Max', provider: 'Alibaba', type: 'chat', context_window: 32000, is_active: true, avg_latency_ms: 600, total_requests: 80000, success_rate: 98.9, cost_per_1k: 0.002 },
    { id: '5', name: 'text-embedding-3', provider: 'OpenAI', type: 'embedding', context_window: 8191, is_active: true, avg_latency_ms: 200, total_requests: 200000, success_rate: 99.9, cost_per_1k: 0.00002 },
    { id: '6', name: 'Whisper-v3', provider: 'OpenAI', type: 'stt', context_window: 0, is_active: true, avg_latency_ms: 3000, total_requests: 5000, success_rate: 97.5, cost_per_1k: 0.006 },
    { id: '7', name: 'TTS-1', provider: 'OpenAI', type: 'tts', context_window: 4096, is_active: true, avg_latency_ms: 2500, total_requests: 3000, success_rate: 99.0, cost_per_1k: 0.015 },
  ];

  const displayModels = models.length > 0 ? models : defaultModels;

  return (
    <div className="flex">
      <Sidebar active="/models" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">模型管理</h2>
        <div className="grid grid-cols-2 gap-6">
          {loading ? (
            <div className="col-span-2 bg-white rounded-xl border p-12 text-center text-gray-400">加载中...</div>
          ) : (
            displayModels.map((model) => (
              <div key={model.id} className="bg-white rounded-xl border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="font-semibold text-gray-800">{model.name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-500">{model.provider}</span>
                      <span className="text-xs bg-blue-100 px-2 py-0.5 rounded text-blue-600">{model.type}</span>
                    </div>
                  </div>
                  <span className={`w-3 h-3 rounded-full ${model.is_active ? 'bg-green-500' : 'bg-gray-300'}`} />
                </div>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <div className="text-gray-400">上下文窗口</div>
                    <div className="font-medium">{model.context_window > 0 ? `${(model.context_window / 1000).toFixed(0)}K` : '-'}</div>
                  </div>
                  <div>
                    <div className="text-gray-400">平均延迟</div>
                    <div className="font-medium">{model.avg_latency_ms}ms</div>
                  </div>
                  <div>
                    <div className="text-gray-400">总请求</div>
                    <div className="font-medium">{model.total_requests.toLocaleString()}</div>
                  </div>
                  <div>
                    <div className="text-gray-400">成功率</div>
                    <div className="font-medium text-green-600">{model.success_rate}%</div>
                  </div>
                  <div className="col-span-2">
                    <div className="text-gray-400">成本/1K tokens</div>
                    <div className="font-medium">${model.cost_per_1k}</div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
