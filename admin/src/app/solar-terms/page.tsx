'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface SolarTerm {
  id: string;
  name: string;
  english_name: string;
  date: string;
  element: string;
  wellness_focus: string[];
  content_count: number;
}

export default function SolarTermsPage() {
  const [terms, setTerms] = useState<SolarTerm[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: SolarTerm[] }>('/api/v1/solar-terms');
      if (res?.data) setTerms(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const defaultTerms: SolarTerm[] = [
    { id: '1', name: '立春', english_name: 'Start of Spring', date: '2月4日', element: '木', wellness_focus: ['养肝护肝', '疏肝理气', '早起散步'], content_count: 15 },
    { id: '2', name: '雨水', english_name: 'Rain Water', date: '2月19日', element: '木', wellness_focus: ['健脾祛湿', '防寒保暖', '适量运动'], content_count: 12 },
    { id: '3', name: '惊蛰', english_name: 'Awakening', date: '3月6日', element: '木', wellness_focus: ['养肝明目', '防风御寒', '清淡饮食'], content_count: 14 },
    { id: '4', name: '春分', english_name: 'Spring Equinox', date: '3月21日', element: '木', wellness_focus: ['阴阳调和', '养肝护脾', '调畅情志'], content_count: 18 },
    { id: '5', name: '清明', english_name: 'Clear & Bright', date: '4月5日', element: '木', wellness_focus: ['养肝柔肝', '踏青舒筋', '防过敏'], content_count: 16 },
    { id: '6', name: '谷雨', english_name: 'Grain Rain', date: '4月20日', element: '木', wellness_focus: ['健脾祛湿', '养肝熄风', '防湿邪'], content_count: 13 },
    { id: '7', name: '立夏', english_name: 'Start of Summer', date: '5月6日', element: '火', wellness_focus: ['养心安神', '清热消暑', '晚睡早起'], content_count: 17 },
    { id: '8', name: '小满', english_name: 'Grain Buds', date: '5月21日', element: '火', wellness_focus: ['清心泻火', '防湿防热', '清淡饮食'], content_count: 11 },
  ];

  const displayTerms = terms.length > 0 ? terms : defaultTerms;
  const elementColors: Record<string, string> = { 木: 'text-green-600 bg-green-100', 火: 'text-red-600 bg-red-100', 土: 'text-yellow-700 bg-yellow-100', 金: 'text-gray-600 bg-gray-100', 水: 'text-blue-600 bg-blue-100' };

  return (
    <div className="flex">
      <Sidebar active="/solar-terms" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">节气管理</h2>
        <div className="grid grid-cols-2 gap-4">
          {loading ? (
            <div className="col-span-2 text-center text-gray-400 py-12">加载中...</div>
          ) : (
            displayTerms.map((term) => (
              <div key={term.id} className="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <span className="text-2xl font-bold text-gray-800">{term.name}</span>
                    <span className="text-sm text-gray-400">{term.english_name}</span>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded ${elementColors[term.element] || 'bg-gray-100'}`}>{term.element}</span>
                </div>
                <div className="text-sm text-gray-500 mb-3">{term.date}</div>
                <div className="flex flex-wrap gap-2 mb-3">
                  {(term.wellness_focus || []).map((f, i) => (
                    <span key={i} className="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded">{f}</span>
                  ))}
                </div>
                <div className="text-xs text-gray-400">{term.content_count} 篇养生内容</div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
