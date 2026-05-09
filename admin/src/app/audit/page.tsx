'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface AuditLog {
  id: string;
  action: string;
  resource_type: string;
  resource_id: string;
  actor: string;
  details: string;
  ip_address: string;
  created_at: string;
}

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => { loadLogs(); }, [page]);

  async function loadLogs() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: AuditLog[] }>(`/api/v1/audit?page=${page}&page_size=50`);
      if (res?.data) setLogs(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const actionColors: Record<string, string> = {
    create: 'bg-green-100 text-green-700',
    update: 'bg-blue-100 text-blue-700',
    delete: 'bg-red-100 text-red-700',
    login: 'bg-purple-100 text-purple-700',
    logout: 'bg-gray-100 text-gray-600',
    export: 'bg-orange-100 text-orange-700',
  };

  return (
    <div className="flex">
      <Sidebar active="/audit" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">审计日志</h2>
          <button onClick={loadLogs} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">刷新</button>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">时间</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">操作</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">资源</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">操作者</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">详情</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">IP</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400">加载中...</td></tr>
              ) : logs.length === 0 ? (
                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400">暂无审计日志</td></tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-400 whitespace-nowrap">{new Date(log.created_at).toLocaleString('zh-CN')}</td>
                    <td className="px-6 py-4"><span className={`px-2 py-1 rounded text-xs font-medium ${actionColors[log.action] || 'bg-gray-100 text-gray-600'}`}>{log.action}</span></td>
                    <td className="px-6 py-4 text-sm text-gray-600">{log.resource_type}/{log.resource_id?.slice(0, 8)}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{log.actor}</td>
                    <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">{log.details}</td>
                    <td className="px-6 py-4 text-sm font-mono text-gray-400">{log.ip_address}</td>
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
