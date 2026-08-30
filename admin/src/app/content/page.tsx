'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, postAPI, putAPI, deleteAPI } from '@/lib/api';

interface Content {
  id: string;
  title: string;
  content_type: string;
  category: string;
  status: 'draft' | 'review' | 'published' | 'archived';
  author_id: string;
  created_at: string;
  updated_at: string;
  body?: string;
  tags?: string[];
}

interface ContentStats {
  total: number;
  draft: number;
  review: number;
  published: number;
  archived: number;
}

interface Tag {
  id: string;
  name: string;
  color: string;
}

const typeLabels: Record<string, string> = {
  article: '文章', video: '视频', audio: '音频',
  recipe: '食谱', exercise: '运动', meditation: '冥想',
};

const statusLabels: Record<string, string> = {
  draft: '草稿', review: '审核中', published: '已发布', archived: '已归档',
};

const statusColors: Record<string, string> = {
  draft: 'bg-yellow-100 text-yellow-700',
  review: 'bg-orange-100 text-orange-700',
  published: 'bg-green-100 text-green-700',
  archived: 'bg-gray-100 text-gray-600',
};

export default function ContentPage() {
  const [contents, setContents] = useState<Content[]>([]);
  const [stats, setStats] = useState<ContentStats>({ total: 0, draft: 0, review: 0, published: 0, archived: 0 });
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState({
    title: '', content_type: 'article', category: '', body: '', tags: [] as string[],
  });

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: '1', page_size: '50' });
      if (filterType !== 'all') params.set('type', filterType);
      if (filterStatus !== 'all') params.set('status', filterStatus);
      
      const [listRes, statsRes, tagsRes] = await Promise.all([
        fetchAPI<{ data: { items: Content[] } }>(`/api/v1/cms/content?${params}`),
        fetchAPI<{ data: ContentStats }>('/api/v1/cms/stats'),
        fetchAPI<{ data: Tag[] }>('/api/v1/cms/tags'),
      ]);
      
      if (listRes?.data?.items) setContents(listRes.data.items);
      if (statsRes?.data) setStats(statsRes.data);
      if (tagsRes?.data) setTags(tagsRes.data);
    } catch (err) {
      console.error('Failed to load content:', err);
    }
    setLoading(false);
  }, [filterType, filterStatus]);

  useEffect(() => {
    const timer = window.setTimeout(() => void loadData(), 0);
    return () => window.clearTimeout(timer);
  }, [loadData]);

  async function handleCreate() {
    try {
      await postAPI('/api/v1/cms/content', form);
      setShowModal(false);
      resetForm();
      loadData();
    } catch {
      alert('创建失败');
    }
  }

  async function handleUpdate() {
    if (!editingId) return;
    try {
      await putAPI(`/api/v1/cms/content/${editingId}`, form);
      setShowModal(false);
      setEditingId(null);
      resetForm();
      loadData();
    } catch {
      alert('更新失败');
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('确定删除此内容？')) return;
    try {
      await deleteAPI(`/api/v1/cms/content/${id}`);
      loadData();
    } catch {
      alert('删除失败');
    }
  }

  async function handleAction(id: string, action: string) {
    try {
      await postAPI(`/api/v1/cms/content/${id}/${action}`, {});
      loadData();
    } catch {
      alert('操作失败');
    }
  }

  async function handleReviewAction(id: string, action: 'approve' | 'reject') {
    try {
      await postAPI(`/api/v1/cms/review/${action}/${id}`, {});
      loadData();
    } catch {
      alert('审核操作失败');
    }
  }

  function openCreate() {
    setEditingId(null);
    resetForm();
    setShowModal(true);
  }

  function openEdit(content: Content) {
    setEditingId(content.id);
    setForm({
      title: content.title,
      content_type: content.content_type,
      category: content.category,
      body: content.body || '',
      tags: content.tags || [],
    });
    setShowModal(true);
  }

  function resetForm() {
    setForm({ title: '', content_type: 'article', category: '', body: '', tags: [] });
  }

  const types = ['all', 'article', 'video', 'audio', 'recipe', 'exercise', 'meditation'];
  const statuses = ['all', 'draft', 'review', 'published', 'archived'];

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar active="/content" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">内容管理 (CMS)</h2>
          <button onClick={openCreate} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">
            + 新建内容
          </button>
        </div>

        {/* 统计卡片 */}
        <div className="grid grid-cols-5 gap-4 mb-6">
          {[
            { label: '全部', value: stats.total, color: 'bg-blue-50 text-blue-700' },
            { label: '草稿', value: stats.draft, color: 'bg-yellow-50 text-yellow-700' },
            { label: '审核中', value: stats.review, color: 'bg-orange-50 text-orange-700' },
            { label: '已发布', value: stats.published, color: 'bg-green-50 text-green-700' },
            { label: '已归档', value: stats.archived, color: 'bg-gray-50 text-gray-700' },
          ].map((s) => (
            <div key={s.label} className={`p-4 rounded-lg ${s.color}`}>
              <div className="text-2xl font-bold">{s.value}</div>
              <div className="text-sm">{s.label}</div>
            </div>
          ))}
        </div>

        {/* 筛选器 */}
        <div className="flex items-center gap-4 mb-6">
          <div className="flex gap-2 flex-wrap">
            {types.map((t) => (
              <button key={t} onClick={() => setFilterType(t)}
                className={`px-3 py-2 rounded-lg text-sm ${filterType === t ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'}`}>
                {typeLabels[t] || '全部'}
              </button>
            ))}
          </div>
          <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border border-gray-200 rounded-lg text-sm bg-white">
            {statuses.map((s) => <option key={s} value={s}>{statusLabels[s] || '全部状态'}</option>)}
          </select>
        </div>

        {/* 内容表格 */}
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">标题</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">类型</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">分类</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">状态</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">更新时间</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {loading ? (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-500">加载中...</td></tr>
              ) : contents.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-500">暂无内容</td></tr>
              ) : (
                contents.map((c) => (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{c.title}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{typeLabels[c.content_type] || c.content_type}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.category}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${statusColors[c.status]}`}>
                        {statusLabels[c.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500">{new Date(c.updated_at).toLocaleDateString('zh-CN')}</td>
                    <td className="px-4 py-3 flex gap-2 flex-wrap">
                      {c.status === 'draft' && (
                        <>
                          <button onClick={() => handleAction(c.id, 'publish')} className="text-xs px-2 py-1 rounded bg-green-50 text-green-600 hover:bg-green-100">直接发布</button>
                          <button onClick={() => handleAction(c.id, 'submit')} className="text-xs px-2 py-1 rounded bg-orange-50 text-orange-600 hover:bg-orange-100">提交审核</button>
                        </>
                      )}
                      {c.status === 'review' && (
                        <>
                          <button onClick={() => handleReviewAction(c.id, 'approve')} className="text-xs px-2 py-1 rounded bg-green-50 text-green-600 hover:bg-green-100">通过</button>
                          <button onClick={() => handleReviewAction(c.id, 'reject')} className="text-xs px-2 py-1 rounded bg-red-50 text-red-600 hover:bg-red-100">拒绝</button>
                        </>
                      )}
                      {c.status === 'published' && (
                        <button onClick={() => handleAction(c.id, 'archive')} className="text-xs px-2 py-1 rounded bg-gray-50 text-gray-600 hover:bg-gray-100">归档</button>
                      )}
                      {c.status === 'archived' && (
                        <button onClick={() => handleAction(c.id, 'publish')} className="text-xs px-2 py-1 rounded bg-green-50 text-green-600 hover:bg-green-100">重新发布</button>
                      )}
                      <button onClick={() => openEdit(c)} className="text-xs px-2 py-1 rounded bg-blue-50 text-blue-600 hover:bg-blue-100">编辑</button>
                      <button onClick={() => handleDelete(c.id)} className="text-xs px-2 py-1 rounded bg-red-50 text-red-600 hover:bg-red-100">删除</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* 新建/编辑弹窗 */}
        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-auto">
              <div className="p-6 border-b border-gray-200 flex justify-between items-center">
                <h3 className="text-lg font-bold">{editingId ? '编辑内容' : '新建内容'}</h3>
                <button onClick={() => { setShowModal(false); setEditingId(null); }} className="text-gray-400 hover:text-gray-600">✕</button>
              </div>
              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">标题</label>
                  <input type="text" value={form.title}
                    onChange={(e) => setForm({ ...form, title: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm" placeholder="输入标题" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">类型</label>
                    <select value={form.content_type}
                      onChange={(e) => setForm({ ...form, content_type: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm">
                      {Object.entries(typeLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">分类</label>
                    <input type="text" value={form.category}
                      onChange={(e) => setForm({ ...form, category: e.target.value })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm" placeholder="如: 节气养生" />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">正文</label>
                  <textarea value={form.body}
                    onChange={(e) => setForm({ ...form, body: e.target.value })}
                    rows={6}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm" placeholder="输入正文内容..." />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">标签</label>
                  <div className="flex gap-2 flex-wrap">
                    {tags.map((t) => (
                      <button key={t.id}
                        onClick={() => {
                          const newTags = form.tags.includes(t.name)
                            ? form.tags.filter((x) => x !== t.name)
                            : [...form.tags, t.name];
                          setForm({ ...form, tags: newTags });
                        }}
                        className={`px-2 py-1 rounded text-xs ${form.tags.includes(t.name) ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'}`}>
                        {t.name}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
              <div className="p-6 border-t border-gray-200 flex justify-end gap-3">
                <button onClick={() => { setShowModal(false); setEditingId(null); }}
                  className="px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50">取消</button>
                <button onClick={editingId ? handleUpdate : handleCreate}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">
                  {editingId ? '保存修改' : '创建内容'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
