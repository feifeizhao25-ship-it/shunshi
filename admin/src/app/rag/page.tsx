'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface KnowledgeDoc {
  id: string;
  title: string;
  category: string;
  source: string;
  chunk_count: number;
  embedding_model: string;
  created_at: string;
  relevance_score?: number;
}

export default function RagPage() {
  const [docs, setDocs] = useState<KnowledgeDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ total_docs: 0, total_chunks: 0, categories: 0, last_indexed: '' });

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [docsRes, statsRes] = await Promise.all([
        fetchAPI<{ data: KnowledgeDoc[] }>('/api/v1/rag/documents?limit=100'),
        fetchAPI<{ data: any }>('/api/v1/rag/stats'),
      ]);
      if (docsRes?.data) setDocs(Array.isArray(docsRes.data) ? docsRes.data : []);
      if (statsRes?.data) {
        const d = statsRes.data;
        setStats({ total_docs: d.total_docs || 0, total_chunks: d.total_chunks || 0, categories: d.categories || 0, last_indexed: d.last_indexed || '' });
      }
    } catch { /* empty */ }
    setLoading(false);
  }

  const catColors: Record<string, string> = {
    '经典方剂': 'bg-amber-100 text-amber-700',
    '经络穴位': 'bg-green-100 text-green-700',
    '中药材': 'bg-emerald-100 text-emerald-700',
    '食疗养生': 'bg-orange-100 text-orange-700',
    '节气养生': 'bg-blue-100 text-blue-700',
    '体质辨识': 'bg-purple-100 text-purple-700',
    '疾病防治': 'bg-red-100 text-red-700',
    '养生功法': 'bg-indigo-100 text-indigo-700',
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/rag" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
          <h2 className="text-2xl font-bold text-gray-800">知识库管理 (RAG)</h2>
          <div className="flex gap-2">
            <button type="button" disabled title="待人工处理：导入尚未接入" className="px-4 py-2 bg-gray-200 text-gray-600 rounded-lg text-sm cursor-not-allowed">导入待人工处理</button>
            <button type="button" disabled title="待人工处理：重建索引尚未接入" className="px-4 py-2 bg-gray-200 text-gray-600 rounded-lg text-sm cursor-not-allowed">重建索引待人工处理</button>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
          {[
            { label: '文档总数', value: stats.total_docs.toLocaleString(), icon: '📄' },
            { label: '文本分块', value: stats.total_chunks.toLocaleString(), icon: '🧩' },
            { label: '知识分类', value: String(stats.categories), icon: '📂' },
            { label: '最近索引', value: stats.last_indexed || '-', icon: '🕐' },
          ].map((s) => (
            <div key={s.label} className="bg-white rounded-xl border border-gray-200 p-6">
              <div className="flex items-center gap-2 mb-1">
                <span>{s.icon}</span>
                <span className="text-sm text-gray-500">{s.label}</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{s.value}</div>
            </div>
          ))}
        </div>

        {/* Documents */}
        <div className="bg-white rounded-xl border border-gray-200 overflow-x-auto">
          <table className="min-w-[720px] w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">标题</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">分类</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">来源</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">分块数</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">向量模型</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">添加时间</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-600">加载中...</td></tr>
              ) : docs.length === 0 ? (
                <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-600">暂无文档</td></tr>
              ) : (
                docs.map((doc) => (
                  <tr key={doc.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-800">{doc.title}</td>
                    <td className="px-6 py-4"><span className={`text-xs px-2 py-1 rounded ${catColors[doc.category] || 'bg-gray-100 text-gray-600'}`}>{doc.category}</span></td>
                    <td className="px-6 py-4 text-sm text-gray-600">{doc.source}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{doc.chunk_count}</td>
                    <td className="px-6 py-4 text-xs font-mono text-gray-600">{doc.embedding_model}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{doc.created_at ? new Date(doc.created_at).toLocaleDateString('zh-CN') : '-'}</td>
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
