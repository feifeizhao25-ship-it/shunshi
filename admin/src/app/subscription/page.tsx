'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, postAPI, putAPI } from '../../lib/api';

interface Subscription {
  id: string;
  user_id: string;
  plan: string;
  status: 'active' | 'cancelled' | 'expired' | 'trial';
  start_date: string;
  end_date: string;
  auto_renew: boolean;
  amount: number;
  payment_method?: string;
}

interface Plan {
  id: string;
  name: string;
  price: number;
  features: string[];
  subscriber_count: number;
}

export default function SubscriptionPage() {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'subs' | 'plans'>('subs');
  const [stats, setStats] = useState({ total_revenue: 0, active_subs: 0, churn_rate: 0, trial_conversion: 0 });

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [subsRes, plansRes, statsRes] = await Promise.all([
        fetchAPI<{ data: Subscription[] }>('/api/v1/subscription?limit=50'),
        fetchAPI<{ data: Plan[] }>('/api/v1/subscription/plans'),
        fetchAPI<{ data: any }>('/api/v1/admin/subscription/stats'),
      ]);
      if (subsRes?.data) setSubscriptions(Array.isArray(subsRes.data) ? subsRes.data : []);
      if (plansRes?.data) setPlans(Array.isArray(plansRes.data) ? plansRes.data : []);
      if (statsRes?.data) {
        const d = statsRes.data;
        setStats({ total_revenue: d.total_revenue || 0, active_subs: d.active_subs || 0, churn_rate: d.churn_rate || 0, trial_conversion: d.trial_conversion || 0 });
      }
    } catch { /* empty */ }
    setLoading(false);
  }

  const statusColors: Record<string, string> = {
    active: 'bg-green-100 text-green-700',
    trial: 'bg-blue-100 text-blue-700',
    cancelled: 'bg-yellow-100 text-yellow-700',
    expired: 'bg-gray-100 text-gray-600',
  };
  const statusLabels: Record<string, string> = { active: '活跃', trial: '试用', cancelled: '已取消', expired: '已过期' };

  return (
    <div className="flex">
      <Sidebar active="/subscription" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">订阅管理</h2>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-6 mb-8">
          {[
            { label: '总收入', value: `¥${stats.total_revenue.toLocaleString()}`, color: 'text-green-600' },
            { label: '活跃订阅', value: stats.active_subs.toLocaleString(), color: 'text-blue-600' },
            { label: '流失率', value: `${(stats.churn_rate * 100).toFixed(1)}%`, color: 'text-orange-600' },
            { label: '试用转化率', value: `${(stats.trial_conversion * 100).toFixed(1)}%`, color: 'text-purple-600' },
          ].map((s) => (
            <div key={s.label} className="bg-white rounded-xl border border-gray-200 p-6">
              <div className="text-sm text-gray-500 mb-1">{s.label}</div>
              <div className={`text-2xl font-bold ${s.color}`}>{s.value}</div>
            </div>
          ))}
        </div>

        {/* Tabs */}
        <div className="flex gap-4 mb-6 border-b border-gray-200">
          <button onClick={() => setTab('subs')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'subs' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>
            订阅列表
          </button>
          <button onClick={() => setTab('plans')} className={`pb-3 text-sm font-medium border-b-2 ${tab === 'plans' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>
            套餐管理
          </button>
        </div>

        {tab === 'subs' && (
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">用户ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">套餐</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">状态</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">金额</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">开始</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">到期</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">自动续费</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {loading ? (
                  <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-400">加载中...</td></tr>
                ) : subscriptions.length === 0 ? (
                  <tr><td colSpan={7} className="px-6 py-12 text-center text-gray-400">暂无订阅数据</td></tr>
                ) : (
                  subscriptions.map((sub) => (
                    <tr key={sub.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-sm font-mono text-gray-600">{sub.user_id?.slice(0, 8)}...</td>
                      <td className="px-6 py-4 text-sm text-gray-800">{sub.plan}</td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 rounded text-xs font-medium ${statusColors[sub.status]}`}>{statusLabels[sub.status]}</span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">¥{sub.amount}</td>
                      <td className="px-6 py-4 text-sm text-gray-400">{sub.start_date ? new Date(sub.start_date).toLocaleDateString('zh-CN') : '-'}</td>
                      <td className="px-6 py-4 text-sm text-gray-400">{sub.end_date ? new Date(sub.end_date).toLocaleDateString('zh-CN') : '-'}</td>
                      <td className="px-6 py-4 text-sm">{sub.auto_renew ? '✅' : '❌'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {tab === 'plans' && (
          <div className="grid grid-cols-3 gap-6">
            {plans.length > 0 ? plans.map((plan) => (
              <div key={plan.id} className="bg-white rounded-xl border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-semibold text-gray-800">{plan.name}</h3>
                  <span className="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded">{plan.subscriber_count} 订阅</span>
                </div>
                <div className="text-3xl font-bold text-gray-900 mb-4">¥{plan.price}<span className="text-sm font-normal text-gray-400">/月</span></div>
                <ul className="space-y-2 text-sm text-gray-600">
                  {(plan.features || []).map((f, i) => <li key={i} className="flex items-center gap-2"><span className="text-green-500">✓</span>{f}</li>)}
                </ul>
              </div>
            )) : (
              ['免费版', '基础版', '高级版', '家庭版'].map((name) => (
                <div key={name} className="bg-white rounded-xl border border-gray-200 p-6">
                  <h3 className="font-semibold text-gray-800 mb-4">{name}</h3>
                  <div className="text-3xl font-bold text-gray-900 mb-4">
                    ¥{name === '免费版' ? '0' : name === '基础版' ? '29' : name === '高级版' ? '59' : '99'}
                    <span className="text-sm font-normal text-gray-400">/月</span>
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </main>
    </div>
  );
}
