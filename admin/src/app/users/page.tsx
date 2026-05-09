'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, deleteAPI, postAPI } from '../../lib/api';

interface User {
  id: string;
  phone?: string;
  nickname?: string;
  avatar_url?: string;
  body_constitution?: string;
  subscription_tier?: string;
  created_at: string;
  last_login?: string;
  is_active: boolean;
  family_count?: number;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [filterTier, setFilterTier] = useState('all');
  const pageSize = 20;

  useEffect(() => {
    loadUsers();
  }, [page, filterTier]);

  async function loadUsers() {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: String(page),
        page_size: String(pageSize),
      });
      if (filterTier !== 'all') params.set('tier', filterTier);
      if (search) params.set('search', search);

      const res = await fetchAPI<{ data: User[]; total: number }>(`/api/v1/users?${params}`);
      if (res?.data) {
        setUsers(Array.isArray(res.data) ? res.data : []);
        setTotal(res.total || 0);
      }
    } catch {
      // Fallback empty
    }
    setLoading(false);
  }

  async function handleToggleActive(userId: string, currentActive: boolean) {
    if (!confirm(currentActive ? '确定禁用该用户？' : '确定启用该用户？')) return;
    try {
      await postAPI(`/api/v1/users/${userId}/${currentActive ? 'deactivate' : 'activate'}`, {});
      loadUsers();
    } catch {
      alert('操作失败');
    }
  }

  const tiers = ['all', 'free', 'basic', 'premium', 'family'];
  const tierLabels: Record<string, string> = { all: '全部', free: '免费', basic: '基础', premium: '高级', family: '家庭' };
  const tierColors: Record<string, string> = { free: 'bg-gray-100 text-gray-600', basic: 'bg-blue-100 text-blue-600', premium: 'bg-purple-100 text-purple-600', family: 'bg-green-100 text-green-600' };
  const totalPages = Math.ceil(total / pageSize);

  return (
    <div className="flex">
      <Sidebar active="/users" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">用户管理</h2>
          <span className="text-sm text-gray-400">共 {total} 位用户</span>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-4 mb-6">
          <div className="flex-1 relative">
            <input
              type="text"
              placeholder="搜索用户ID/手机号/昵称..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && loadUsers()}
              className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex gap-2">
            {tiers.map((tier) => (
              <button
                key={tier}
                onClick={() => setFilterTier(tier)}
                className={`px-3 py-2 rounded-lg text-sm transition-colors ${
                  filterTier === tier ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {tierLabels[tier]}
              </button>
            ))}
          </div>
          <button onClick={loadUsers} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">
            刷新
          </button>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">用户ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">昵称</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">手机号</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">体质</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">订阅</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">状态</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">注册时间</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-400">加载中...</td></tr>
              ) : users.length === 0 ? (
                <tr><td colSpan={8} className="px-6 py-12 text-center text-gray-400">暂无用户数据</td></tr>
              ) : (
                users.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-mono text-gray-600">{user.id.slice(0, 8)}...</td>
                    <td className="px-6 py-4 text-sm text-gray-800">{user.nickname || '-'}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{user.phone || '-'}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{user.body_constitution || '-'}</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${tierColors[user.subscription_tier || 'free'] || 'bg-gray-100 text-gray-600'}`}>
                        {tierLabels[user.subscription_tier || 'free']}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex w-2 h-2 rounded-full ${user.is_active ? 'bg-green-500' : 'bg-red-500'}`} />
                      <span className="ml-2 text-sm text-gray-600">{user.is_active ? '活跃' : '禁用'}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-400">
                      {new Date(user.created_at).toLocaleDateString('zh-CN')}
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleToggleActive(user.id, user.is_active)}
                        className={`text-xs px-3 py-1 rounded ${user.is_active ? 'bg-red-50 text-red-600 hover:bg-red-100' : 'bg-green-50 text-green-600 hover:bg-green-100'}`}
                      >
                        {user.is_active ? '禁用' : '启用'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between mt-6">
            <span className="text-sm text-gray-400">
              第 {page}/{totalPages} 页，共 {total} 条
            </span>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page === 1}
                className="px-3 py-2 bg-white border border-gray-200 rounded-lg text-sm disabled:opacity-50 hover:bg-gray-50"
              >
                上一页
              </button>
              <button
                onClick={() => setPage(Math.min(totalPages, page + 1))}
                disabled={page === totalPages}
                className="px-3 py-2 bg-white border border-gray-200 rounded-lg text-sm disabled:opacity-50 hover:bg-gray-50"
              >
                下一页
              </button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
