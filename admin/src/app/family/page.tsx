'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface Family {
  id: string;
  name: string;
  creator_id: string;
  member_count: number;
  subscription: string;
  created_at: string;
  members: { id: string; name: string; role: string; constitution?: string }[];
}

export default function FamilyPage() {
  const [families, setFamilies] = useState<Family[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: Family[] }>('/api/v1/family?limit=50');
      if (res?.data) setFamilies(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  return (
    <div className="flex">
      <Sidebar active="/family" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">家庭管理</h2>
          <span className="text-sm text-gray-400">{families.length} 个家庭</span>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">家庭名称</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">创建者</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">成员数</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">订阅</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">创建时间</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-400">加载中...</td></tr>
              ) : families.length === 0 ? (
                <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-400">暂无家庭数据</td></tr>
              ) : (
                families.map((f) => (
                  <tr key={f.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-800">{f.name}</td>
                    <td className="px-6 py-4 text-sm font-mono text-gray-600">{f.creator_id?.slice(0, 8)}...</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{f.member_count} 人</td>
                    <td className="px-6 py-4"><span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">{f.subscription || 'free'}</span></td>
                    <td className="px-6 py-4 text-sm text-gray-400">{new Date(f.created_at).toLocaleDateString('zh-CN')}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
