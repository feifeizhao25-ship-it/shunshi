'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';
import { asList, readError } from '@/lib/format';

interface Constitution {
  id: string;
  name: string;
  description?: string;
  percentage?: number;
}

export default function ConstitutionPage() {
  const [data, setData] = useState<Constitution[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    setError('');
    try {
      const res = await fetchAPI<unknown>('/api/v1/admin/constitution/stats');
      const message = readError(res);
      if (message) setError(message);
      setData(asList<Constitution>(res).filter((item) => item?.name));
    } catch {
      setError('数据暂时读不到，请稍后刷新。');
      setData([]);
    }
    setLoading(false);
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/constitution" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">体质管理</h2>
        {error && <div role="alert" className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg">{error}</div>}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="font-semibold text-gray-800 mb-4">用户体质分布</h3>
          {loading ? <p className="text-gray-600">加载中...</p> : data.length === 0 ? (
            <p className="text-gray-600">还没有体质分布。这里不展示示例百分比。</p>
          ) : (
            <div className="space-y-4">
              {data.map((item) => {
                const pct = typeof item.percentage === 'number' ? item.percentage : null;
                return (
                  <div key={item.id || item.name} className="flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-4">
                    <span className="sm:w-16 text-sm font-medium text-gray-800">{item.name}</span>
                    <div className="flex-1 bg-gray-100 rounded-full h-6 overflow-hidden">
                      {pct != null && (
                        <div className="h-full bg-green-700 rounded-full" style={{ width: `${Math.min(Math.max(pct, 0), 100)}%` }} />
                      )}
                    </div>
                    <span className="text-sm text-gray-700 sm:w-16">{pct == null ? '未提供' : `${pct}%`}</span>
                    {item.description && <span className="text-xs text-gray-600 sm:w-48">{item.description}</span>}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
