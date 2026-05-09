'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface Constitution {
  id: string;
  name: string;
  description: string;
  percentage: number;
  recommendations: string[];
}

export default function ConstitutionPage() {
  const [data, setData] = useState<Constitution[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: Constitution[] }>('/api/v1/admin/constitution/stats');
      if (res?.data) setData(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const defaultData: Constitution[] = [
    { id: '1', name: '平和质', description: '阴阳气血调和，体态适中', percentage: 28, recommendations: ['保持规律作息', '适量运动'] },
    { id: '2', name: '气虚质', description: '元气不足，疲乏气短', percentage: 15, recommendations: ['补气养气', '避免过度劳累'] },
    { id: '3', name: '阳虚质', description: '阳气不足，手足不温', percentage: 12, recommendations: ['温补阳气', '少食寒凉'] },
    { id: '4', name: '阴虚质', description: '阴液亏少，口燥咽干', percentage: 10, recommendations: ['滋阴润燥', '避免熬夜'] },
    { id: '5', name: '痰湿质', description: '痰湿凝聚，形体肥胖', percentage: 11, recommendations: ['化痰祛湿', '少食甜腻'] },
    { id: '6', name: '湿热质', description: '湿热内蕴，面垢油光', percentage: 8, recommendations: ['清热化湿', '饮食清淡'] },
    { id: '7', name: '血瘀质', description: '血行不畅，肤色晦暗', percentage: 6, recommendations: ['活血化瘀', '适量运动'] },
    { id: '8', name: '气郁质', description: '气机郁滞，神情抑郁', percentage: 7, recommendations: ['疏肝解郁', '调节情绪'] },
    { id: '9', name: '特禀质', description: '先天禀赋异常，过敏体质', percentage: 3, recommendations: ['避免过敏原', '增强免疫'] },
  ];

  const displayData = data.length > 0 ? data : defaultData;

  return (
    <div className="flex">
      <Sidebar active="/constitution" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">体质管理</h2>
        <div className="bg-white rounded-xl border border-gray-200 p-6 mb-8">
          <h3 className="font-semibold text-gray-800 mb-4">用户体质分布</h3>
          <div className="space-y-4">
            {displayData.map((c) => (
              <div key={c.id} className="flex items-center gap-4">
                <span className="w-16 text-sm font-medium text-gray-700">{c.name}</span>
                <div className="flex-1 bg-gray-100 rounded-full h-6 overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-green-400 to-green-600 rounded-full flex items-center pl-3"
                    style={{ width: `${Math.max(c.percentage, 2)}%` }}>
                    <span className="text-xs text-white font-medium">{c.percentage}%</span>
                  </div>
                </div>
                <span className="w-48 text-xs text-gray-400 truncate">{c.description}</span>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
