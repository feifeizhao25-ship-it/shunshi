'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';
import { asList, readError } from '@/lib/format';

interface AIModel {
  id: string;
  name: string;
  provider?: string;
  status?: string;
  is_default?: boolean;
  is_active?: boolean;
  max_tokens?: number;
  type?: string;
}

export default function ModelsPage() {
  const [models, setModels] = useState<AIModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => { loadModels(); }, []);

  async function loadModels() {
    setLoading(true);
    setError('');
    try {
      const res = await fetchAPI<unknown>('/api/v1/admin/config/ai-models');
      const message = readError(res);
      if (message) setError(message);
      setModels(asList<AIModel>(res).filter((item) => item && item.name));
    } catch {
      setError('数据暂时读不到，请稍后刷新。');
      setModels([]);
    }
    setLoading(false);
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/models" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">模型管理</h2>
        <p className="text-sm text-gray-600 mb-6">只展示接口返回的国内模型，不填请求量、成功率和费用。</p>
        {error && <div role="alert" className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg">{error}</div>}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {loading ? (
            <div className="md:col-span-2 bg-white rounded-xl border p-12 text-center text-gray-600">加载中...</div>
          ) : models.length === 0 ? (
            <div className="md:col-span-2 bg-white rounded-xl border p-12 text-center text-gray-600">暂无已配置的模型</div>
          ) : (
            models.map((model) => {
              const active = model.is_active ?? model.status === 'active';
              return (
                <div key={model.id || model.name} className="bg-white rounded-xl border border-gray-200 p-6">
                  <div className="flex items-start justify-between gap-3 mb-4">
                    <div className="min-w-0">
                      <h3 className="font-semibold text-gray-800 break-words">{model.name}</h3>
                      <div className="flex flex-wrap items-center gap-2 mt-2">
                        {model.provider && <span className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-700">{model.provider}</span>}
                        {model.type && <span className="text-xs bg-blue-100 px-2 py-0.5 rounded text-blue-700">{model.type}</span>}
                        {model.is_default && <span className="text-xs bg-green-100 px-2 py-0.5 rounded text-green-800">默认</span>}
                      </div>
                    </div>
                    <span className={`mt-1 shrink-0 w-3 h-3 rounded-full ${active ? 'bg-green-600' : 'bg-gray-300'}`} aria-label={active ? '启用' : '停用'} />
                  </div>
                  <div className="text-sm text-gray-600">
                    单次上限：{typeof model.max_tokens === 'number' ? `${model.max_tokens.toLocaleString('zh-CN')} token` : '接口未提供'}
                  </div>
                </div>
              );
            })
          )}
        </div>
      </main>
    </div>
  );
}
