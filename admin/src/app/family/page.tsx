'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface Family {
  id: string;
  name: string | null;
  record_count: number;
  account_count: number;
  updated_at: string | null;
}

interface FamilyResponse {
  success?: boolean;
  data?: Family[];
  total?: number;
  error?: unknown;
}

export default function FamilyPage() {
  const [families, setFamilies] = useState<Family[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [attempt, setAttempt] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const pageSize = 20;

  useEffect(() => {
    const controller = new AbortController();
    async function loadData() {
      setLoading(true);
      setError(false);
      setFamilies([]);
      try {
        const res = await fetchAPI<FamilyResponse>(
          `/api/v1/admin/families?page=${page}&page_size=${pageSize}`,
          { signal: controller.signal },
        );
        if (controller.signal.aborted) return;
        if (res.error || res.success !== true || !Array.isArray(res.data) ||
            !Number.isInteger(res.total) || res.total! < 0) {
          throw new Error('家庭统计未确认');
        }
        setFamilies(res.data);
        setTotal(res.total!);
      } catch {
        if (!controller.signal.aborted) setError(true);
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }
    void loadData();
    return () => controller.abort();
  }, [page, attempt]);

  return (
    <div className="flex">
      <Sidebar active="/family" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-2xl font-bold text-gray-800">家庭记录管理</h2>
          <button disabled={loading} onClick={() => setAttempt(value => value + 1)}
            className="px-3 py-2 border rounded disabled:opacity-50">刷新</button>
        </div>
        <p className="text-sm text-gray-600 mb-6">
          汇总已保存的家庭关系记录。记录条数不等于注册成员人数或付费会员席位。
        </p>
        {error ? (
          <div role="alert" className="bg-white rounded-xl border p-6">
            <p>家庭统计读取失败，请确认管理员登录状态和网络后重试。</p>
            <button className="mt-3 underline" onClick={() => setAttempt(value => value + 1)}>重新读取</button>
          </div>
        ) : (
          <div className="bg-white rounded-xl border border-gray-200 overflow-x-auto">
            <table className="hidden md:table w-full">
              <caption className="text-left px-6 py-3 text-sm text-gray-600">
                {loading ? '正在读取家庭统计…' : `共 ${total} 个有记录的家庭`}
              </caption>
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  {['家庭名称', '记录条数', '记录所属账号数', '最近更新时间'].map(title => (
                    <th key={title} scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-600">{title}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {loading ? (
                  <tr><td colSpan={4} className="px-6 py-12 text-center">加载中...</td></tr>
                ) : families.length === 0 ? (
                  <tr><td colSpan={4} className="px-6 py-12 text-center">{page === 1 ? '暂无家庭记录' : '本页暂无记录，请返回上一页'}</td></tr>
                ) : families.map(family => (
                  <tr key={family.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium">{family.name?.trim() || '未命名家庭'}</td>
                    <td className="px-6 py-4 text-sm">{family.record_count}</td>
                    <td className="px-6 py-4 text-sm">{family.account_count}</td>
                    <td className="px-6 py-4 text-sm">{family.updated_at || '暂无记录'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="md:hidden p-4 space-y-4">
              <p className="text-sm text-gray-600">{loading ? '正在读取家庭统计…' : `共 ${total} 个有记录的家庭`}</p>
              {!loading && families.length === 0 && <p>本页暂无家庭记录</p>}
              {!loading && families.map(family => (
                <article key={family.id} className="border rounded-lg p-4">
                  <h3 className="font-semibold break-words">{family.name?.trim() || '未命名家庭'}</h3>
                  <dl className="text-sm space-y-3 mt-4">
                    <div className="flex justify-between gap-3"><dt>记录条数</dt><dd>{family.record_count}</dd></div>
                    <div className="flex justify-between gap-3"><dt>记录所属账号数</dt><dd>{family.account_count}</dd></div>
                    <div><dt className="text-gray-600">最近更新时间</dt><dd className="mt-1 break-words">{family.updated_at || '暂无记录'}</dd></div>
                  </dl>
                </article>
              ))}
            </div>
          </div>
        )}
        <nav aria-label="家庭列表分页" className="flex gap-4 items-center mt-4">
          <button disabled={loading || page <= 1} onClick={() => setPage(value => value - 1)}
            className="border rounded px-3 py-2 disabled:opacity-50">上一页</button>
          <span>第 {page} 页</span>
          <button disabled={loading || error || page * pageSize >= total} onClick={() => setPage(value => value + 1)}
            className="border rounded px-3 py-2 disabled:opacity-50">下一页</button>
        </nav>
      </main>
    </div>
  );
}
