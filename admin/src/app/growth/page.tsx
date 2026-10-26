'use client';

import { useCallback, useEffect, useState } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, postAPI } from '../../lib/api';

interface Draft {
  id: string;
  platform: string;
  title: string;
  status: string;
  aigc_labeled: boolean;
  external_posted: boolean;
}

interface Funnel {
  counts: Record<string, number>;
  attributed_signups: number;
  arpu_yuan: number;
  projected_revenue_yuan: number;
}

export default function GrowthPage() {
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [funnel, setFunnel] = useState<Funnel | null>(null);
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    const [queue, funnelRes] = await Promise.all([
      fetchAPI<{ data: Draft[] }>('/api/v1/admin/growth/queue'),
      fetchAPI<{ data: Funnel }>('/api/v1/admin/growth/funnel'),
    ]);
    setDrafts(Array.isArray(queue?.data) ? queue.data : []);
    setFunnel(funnelRes?.data && !Array.isArray(funnelRes.data) ? funnelRes.data : null);
    setLoading(false);
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  async function confirmDraft(id: string) {
    setNotice('');
    const res = await postAPI<{ data: { external_posted?: boolean; published?: boolean } }>(
      `/api/v1/admin/growth/queue/${id}/confirm`,
      {},
    );
    if (res?.data?.external_posted || res?.data?.published) {
      setNotice('确认没有发出去。请再看一眼队列。');
    } else {
      setNotice('已记下人工确认。稿子仍在队列里，没有发到站外。');
    }
    await load();
  }

  const counts = funnel?.counts || {};

  return (
    <div className="flex">
      <Sidebar active="/growth" />
      <main className="flex-1 p-6 md:p-8 bg-gray-50 min-h-screen">
        <h1 className="text-2xl font-semibold text-gray-900">增长草稿</h1>
        <p className="mt-2 text-sm text-gray-500">
          小红书、公众号、视频号、抖音、知乎只生成草稿。确认表示人看过，系统不会代发。
        </p>
        {notice ? <p className="mt-3 text-sm text-blue-700">{notice}</p> : null}
        <section className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            ['落地', counts.landing_view || 0],
            ['注册', counts.signup || 0],
            ['第一次作息', counts.first_rhythm_logged || 0],
            ['付费', counts.subscription_paid || 0],
          ].map(([label, value]) => (
            <div key={String(label)} className="bg-white rounded-lg border border-gray-200 p-4">
              <div className="text-xs text-gray-400">{label}</div>
              <div className="text-xl font-semibold text-gray-900">{value}</div>
            </div>
          ))}
        </section>
        <p className="mt-3 text-sm text-gray-500">
          规划 ARPU ¥{funnel?.arpu_yuan ?? 600}，预测收入 ¥{funnel?.projected_revenue_yuan ?? 0}
          ，带来的注册 {funnel?.attributed_signups ?? 0}
        </p>
        <section className="mt-6 bg-white rounded-lg border border-gray-200">
          {loading ? <p className="p-4 text-sm text-gray-400">加载中</p> : null}
          {!loading && drafts.length === 0 ? (
            <p className="p-4 text-sm text-gray-400">还没有待确认的草稿</p>
          ) : null}
          <ul>
            {drafts.map((draft) => (
              <li key={draft.id} className="flex items-center justify-between gap-3 px-4 py-3 border-t border-gray-100">
                <div>
                  <div className="text-sm text-gray-900">{draft.title || '未命名草稿'}</div>
                  <div className="text-xs text-gray-400">
                    {draft.platform} · {draft.status}
                    {draft.aigc_labeled ? ' · 已标人工智能生成' : ''}
                    {draft.external_posted ? ' · 异常：标记了已外发' : ''}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => confirmDraft(draft.id)}
                  disabled={draft.status === 'human_confirmed'}
                  className="px-3 py-1.5 text-sm rounded-lg bg-blue-600 text-white disabled:bg-gray-200 disabled:text-gray-500"
                >
                  人工确认
                </button>
              </li>
            ))}
          </ul>
        </section>
      </main>
    </div>
  );
}
