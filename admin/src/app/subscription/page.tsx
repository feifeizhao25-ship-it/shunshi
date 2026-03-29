'use client';

import { useEffect, useState } from 'react';
import { fetchAPI } from '@/lib/api';

/* ---------- types ---------- */
interface Product {
  id: string;
  name: string;
  tier: string;
  price_monthly: number;
  price_yearly: number;
  features: string[];
  max_ai_calls: number;
  max_content: number;
  highlight?: boolean;
}

/* ---------- fallback ---------- */
const fallbackProducts: Product[] = [
  {
    id: 'free',
    name: '免费版',
    tier: 'free',
    price_monthly: 0,
    price_yearly: 0,
    features: ['每日3次AI对话', '基础养生文章', '节气提醒', '社区浏览'],
    max_ai_calls: 3,
    max_content: 10,
  },
  {
    id: 'yangxin',
    name: '养心会员',
    tier: 'yangxin',
    price_monthly: 29.9,
    price_yearly: 299,
    features: ['无限AI对话', '全部养生内容', '个性化食疗方案', '专属节气养生', '优先客服'],
    max_ai_calls: -1,
    max_content: -1,
  },
  {
    id: 'yiyang',
    name: '颐养会员',
    tier: 'yiyang',
    price_monthly: 59.9,
    price_yearly: 599,
    features: ['养心会员全部权益', 'AI体质分析报告', '专属健康顾问', '运动计划定制', '家庭共享（3人）', '数据导出'],
    max_ai_calls: -1,
    max_content: -1,
    highlight: true,
  },
  {
    id: 'jiahe',
    name: '家和会员',
    tier: 'jiahe',
    price_monthly: 99.9,
    price_yearly: 999,
    features: ['颐养会员全部权益', '家庭共享（10人）', '1对1健康顾问', '线下活动优先', '体检报告解读', '急救知识课程', 'VIP专属通道'],
    max_ai_calls: -1,
    max_content: -1,
  },
];

const fallbackActiveSubs = 1024;

/* ---------- helpers ---------- */
const tierColors: Record<string, { border: string; bg: string; text: string; badge: string }> = {
  free: { border: 'border-gray-200', bg: 'bg-gray-50', text: 'text-gray-600', badge: 'bg-gray-100 text-gray-600' },
  yangxin: { border: 'border-blue-300', bg: 'bg-blue-50', text: 'text-blue-700', badge: 'bg-blue-100 text-blue-700' },
  yiyang: { border: 'border-violet-400', bg: 'bg-violet-50', text: 'text-violet-700', badge: 'bg-violet-100 text-violet-700' },
  jiahe: { border: 'border-amber-400', bg: 'bg-amber-50', text: 'text-amber-700', badge: 'bg-amber-100 text-amber-700' },
};

const tierOrder = ['free', 'yangxin', 'yiyang', 'jiahe'];

const featureMatrix: { feature: string; free: string; yangxin: string; yiyang: string; jiahe: string }[] = [
  { feature: 'AI对话次数', free: '3次/天', yangxin: '无限', yiyang: '无限', jiahe: '无限' },
  { feature: '养生内容', free: '基础', yangxin: '全部', yiyang: '全部+定制', jiahe: '全部+定制' },
  { feature: '个性化食疗', free: '—', yangxin: '✓', yiyang: '✓', jiahe: '✓' },
  { feature: '节气养生', free: '基础', yangxin: '专属', yiyang: '专属', jiahe: '专属' },
  { feature: '健康顾问', free: '—', yangxin: '—', yiyang: '✓', jiahe: '1对1' },
  { feature: '家庭共享', free: '—', yangxin: '—', yiyang: '3人', jiahe: '10人' },
  { feature: '体检报告解读', free: '—', yangxin: '—', yiyang: '—', jiahe: '✓' },
  { feature: '线下活动', free: '—', yangxin: '—', yiyang: '—', jiahe: '优先' },
  { feature: '数据导出', free: '—', yangxin: '—', yiyang: '✓', jiahe: '✓' },
  { feature: '优先客服', free: '—', yangxin: '✓', yiyang: '✓', jiahe: 'VIP' },
];

/* ---------- page ---------- */
export default function SubscriptionPage() {
  const [products, setProducts] = useState<Product[]>(fallbackProducts);
  const [activeSubs, setActiveSubs] = useState(fallbackActiveSubs);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const res = (await fetchAPI('/api/v1/subscription/products')) as any;
        if (res && !res.error) {
          const list: Product[] = Array.isArray(res) ? res : res.data || res.products || [];
          if (list.length > 0) {
            // Sort by tier order
            list.sort((a, b) => tierOrder.indexOf(a.tier) - tierOrder.indexOf(b.tier));
            setProducts(list);
          }
          // active subs
          const subs = (res as any).active_subscriptions ?? (res as any).activeSubscriptions ?? null;
          if (subs !== null) setActiveSubs(subs);
        }
      } catch {}
      setLoading(false);
    }
    load();
  }, []);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">会员商品管理</h2>
        <div className="bg-white rounded-lg border border-gray-200 px-5 py-3">
          <span className="text-sm text-gray-500">当前活跃订阅</span>
          <span className="ml-2 text-lg font-bold text-blue-600">{activeSubs.toLocaleString()}</span>
        </div>
      </div>

      {loading && (
        <div className="flex items-center gap-2 text-sm text-gray-400 mb-4">
          <span className="animate-spin">⏳</span> 正在加载数据…
        </div>
      )}

      {/* Product cards */}
      <div className="grid grid-cols-4 gap-6 mb-10">
        {products.map((p) => {
          const colors = tierColors[p.tier] || tierColors.free;
          const yearlySavings = p.price_yearly ? Math.round(p.price_monthly * 12 - p.price_yearly) : 0;
          return (
            <div
              key={p.id}
              className={`relative bg-white rounded-xl border-2 ${p.highlight ? 'border-violet-500 shadow-lg shadow-violet-100' : colors.border} p-6 flex flex-col`}
            >
              {p.highlight && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-violet-500 text-white text-xs font-medium px-3 py-1 rounded-full">
                  推荐
                </div>
              )}
              <div className="mb-4">
                <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${colors.badge}`}>
                  {p.name}
                </span>
              </div>
              <div className="mb-1">
                <span className="text-sm text-gray-400">月付</span>
                <span className="text-2xl font-bold ml-1">
                  ¥{p.price_monthly === 0 ? '免费' : p.price_monthly}
                </span>
                {p.price_monthly > 0 && <span className="text-sm text-gray-400">/月</span>}
              </div>
              <div className="mb-4">
                <span className="text-sm text-gray-400">年付</span>
                <span className="text-lg font-semibold ml-1">
                  ¥{p.price_yearly || p.price_monthly * 12}
                </span>
                <span className="text-sm text-gray-400">/年</span>
                {yearlySavings > 0 && (
                  <span className="ml-1 text-xs text-green-600 font-medium">省¥{yearlySavings}</span>
                )}
              </div>
              <ul className="flex-1 space-y-2 text-sm text-gray-600">
                {(p.features || []).map((f) => (
                  <li key={f} className="flex items-start gap-2">
                    <span className="text-green-500 mt-0.5">✓</span>
                    {f}
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </div>

      {/* Feature comparison table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="font-semibold text-lg">权益对比</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50">
                <th className="text-left px-6 py-3 font-medium text-gray-500">权益</th>
                {tierOrder.map((t) => (
                  <th key={t} className="text-center px-4 py-3 font-medium text-gray-700">
                    {products.find((p) => p.tier === t)?.name || t}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {featureMatrix.map((row) => (
                <tr key={row.feature} className="hover:bg-gray-50">
                  <td className="px-6 py-3 text-gray-600">{row.feature}</td>
                  {tierOrder.map((t) => (
                    <td key={t} className="text-center px-4 py-3">
                      <span className={(row as any)[t] === '—' ? 'text-gray-300' : 'text-gray-700'}>
                        {(row as any)[t]}
                      </span>
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
