'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';
import { asList, formatMonthDay, readError } from '@/lib/format';

interface SolarTerm {
  id: string;
  name: string;
  alias?: string;
  emoji?: string;
  description?: string;
  start_date?: string;
  end_date?: string;
  suggestions?: string[];
}

export default function SolarTermsPage() {
  const [terms, setTerms] = useState<SolarTerm[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    setError('');
    try {
      const res = await fetchAPI<unknown>('/api/v1/solar-terms');
      const message = readError(res);
      if (message) setError(message);
      setTerms(asList<SolarTerm>(res).filter((item) => item?.name));
    } catch {
      setError('数据暂时读不到，请稍后刷新。');
      setTerms([]);
    }
    setLoading(false);
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/solar-terms" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">节气管理</h2>
        <p className="text-sm text-gray-600 mb-6">日期来自节气表里每年重复的月日，不展示没有返回的内容篇数。</p>
        {error && <div role="alert" className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg">{error}</div>}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {loading ? (
            <div className="md:col-span-2 text-center text-gray-600 py-12">加载中...</div>
          ) : terms.length === 0 ? (
            <div className="md:col-span-2 bg-white rounded-xl border p-12 text-center text-gray-600">暂无节气数据</div>
          ) : (
            terms.map((term) => {
              const start = formatMonthDay(term.start_date);
              const end = formatMonthDay(term.end_date);
              const range = start && end ? `${start} – ${end}` : start || end || '日期未提供';
              return (
                <div key={term.id || term.name} className="bg-white rounded-xl border border-gray-200 p-5">
                  <div className="flex items-start justify-between gap-3 mb-2">
                    <div className="min-w-0">
                      <div className="text-2xl font-bold text-gray-800 break-words">{term.emoji ? `${term.emoji} ` : ''}{term.name}</div>
                      {term.alias && <div className="text-sm text-gray-600 mt-1">{term.alias}</div>}
                    </div>
                  </div>
                  <div className="text-sm text-gray-700 mb-3">{range}</div>
                  {term.description && <p className="text-sm text-gray-600 mb-3 leading-6">{term.description}</p>}
                  <div className="flex flex-wrap gap-2">
                    {(term.suggestions || []).map((item) => (
                      <span key={item} className="text-xs bg-blue-50 text-blue-800 px-2 py-1 rounded">{item}</span>
                    ))}
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
