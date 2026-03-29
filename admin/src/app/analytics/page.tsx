'use client';

import { useEffect, useState } from 'react';
import { fetchAPI } from '@/lib/api';

/* ---------- types ---------- */
interface TopCard {
  label: string;
  value: string;
  change: string;
  color: string;
}

interface DonutSlice {
  label: string;
  value: number;
  color: string;
}

interface BarRow {
  label: string;
  value: number;
  max: number;
  color: string;
}

/* ---------- fallback data ---------- */
const fallbackCards: TopCard[] = [
  { label: '总用户数', value: '12,486', change: '+128 本月', color: 'bg-blue-500' },
  { label: '付费用户', value: '1,024', change: '+56 本月', color: 'bg-emerald-500' },
  { label: '今日AI调用', value: '8,342', change: '+12% 较昨日', color: 'bg-violet-500' },
  { label: '今日告警', value: '7', change: '-3 较昨日', color: 'bg-amber-500' },
];

const fallbackMembership: DonutSlice[] = [
  { label: '免费用户', value: 62, color: 'bg-gray-300' },
  { label: '养心会员', value: 22, color: 'bg-blue-400' },
  { label: '颐养会员', value: 11, color: 'bg-violet-400' },
  { label: '家和会员', value: 5, color: 'bg-amber-400' },
];

const fallbackContentTypes: DonutSlice[] = [
  { label: '养生文章', value: 45, color: 'bg-green-400' },
  { label: '食疗方案', value: 20, color: 'bg-orange-400' },
  { label: '节气提醒', value: 18, color: 'bg-cyan-400' },
  { label: '运动指导', value: 12, color: 'bg-pink-400' },
  { label: '其他', value: 5, color: 'bg-gray-300' },
];

const fallbackSafetyTrend: BarRow[] = [
  { label: '周一', value: 12, max: 20, color: 'bg-red-400' },
  { label: '周二', value: 8, max: 20, color: 'bg-orange-400' },
  { label: '周三', value: 15, max: 20, color: 'bg-red-400' },
  { label: '周四', value: 5, max: 20, color: 'bg-yellow-400' },
  { label: '周五', value: 7, max: 20, color: 'bg-orange-400' },
  { label: '周六', value: 3, max: 20, color: 'bg-green-400' },
  { label: '周日', value: 4, max: 20, color: 'bg-green-400' },
];

const fallbackTopModels: BarRow[] = [
  { label: 'GLM-5-Turbo', value: 4520, max: 5000, color: 'bg-violet-500' },
  { label: 'GLM-5-Plus', value: 2100, max: 5000, color: 'bg-blue-500' },
  { label: 'GLM-5-Flash', value: 1200, max: 5000, color: 'bg-cyan-500' },
  { label: 'Embedding-3', value: 340, max: 5000, color: 'bg-emerald-500' },
  { label: '其他', value: 182, max: 5000, color: 'bg-gray-400' },
];

/* ---------- components ---------- */

function DonutChart({ data, title }: { data: DonutSlice[]; title: string }) {
  const total = data.reduce((s, d) => s + d.value, 0);
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <h3 className="font-semibold mb-4">{title}</h3>
      {/* CSS donut */}
      <div className="flex items-center gap-8">
        <div className="relative w-36 h-36 shrink-0">
          <svg viewBox="0 0 36 36" className="w-full h-full -rotate-90">
            {data.reduce<{ acc: number; slices: { offset: number; value: number; color: string }[] }>(
              (prev, d) => {
                const pct = (d.value / total) * 100;
                const offset = prev.acc;
                prev.slices.push({ offset, value: pct, color: d.color.replace('bg-', '#') });
                prev.acc += pct;
                return prev;
              },
              { acc: 0, slices: [] },
            ).slices.map((s, i) => (
              <circle
                key={i}
                r="15.91549430918954"
                cx="18"
                cy="18"
                fill="none"
                stroke={s.color}
                strokeWidth="3.2"
                strokeDasharray={`${s.value} ${100 - s.value}`}
                strokeDashoffset={`${-s.offset}`}
                className="transition-all duration-500"
              />
            ))}
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-sm font-medium text-gray-500">{total}%</span>
          </div>
        </div>
        <div className="flex flex-col gap-2 text-sm">
          {data.map((d) => (
            <div key={d.label} className="flex items-center gap-2">
              <span className={`w-3 h-3 rounded-sm ${d.color}`} />
              <span className="text-gray-600">{d.label}</span>
              <span className="font-medium text-gray-800">{d.value}%</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function BarChart({ data, title }: { data: BarRow[]; title: string }) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-6">
      <h3 className="font-semibold mb-4">{title}</h3>
      <div className="space-y-3">
        {data.map((d) => (
          <div key={d.label} className="flex items-center gap-3">
            <span className="text-sm text-gray-500 w-20 shrink-0 text-right">{d.label}</span>
            <div className="flex-1 h-5 bg-gray-100 rounded overflow-hidden">
              <div
                className={`h-full rounded ${d.color} transition-all duration-500`}
                style={{ width: `${(d.value / d.max) * 100}%` }}
              />
            </div>
            <span className="text-sm font-medium text-gray-700 w-16 text-right">{d.value.toLocaleString()}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ---------- page ---------- */
export default function AnalyticsPage() {
  const [cards, setCards] = useState<TopCard[]>(fallbackCards);
  const [membership, setMembership] = useState<DonutSlice[]>(fallbackMembership);
  const [contentTypes, setContentTypes] = useState<DonutSlice[]>(fallbackContentTypes);
  const [safetyTrend, setSafetyTrend] = useState<BarRow[]>(fallbackSafetyTrend);
  const [topModels, setTopModels] = useState<BarRow[]>(fallbackTopModels);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      // Users stats
      try {
        const usersRes = (await fetchAPI('/api/v1/auth/users')) as any;
        if (usersRes && !usersRes.error) {
          const list = Array.isArray(usersRes) ? usersRes : usersRes.data || [];
          const total = list.length;
          const paid = list.filter((u: any) => u.subscription && u.subscription !== 'free').length;
          setCards((prev) => [
            { ...prev[0], value: total.toLocaleString() },
            { ...prev[1], value: paid.toLocaleString() },
            prev[2],
            prev[3],
          ]);
          // membership distribution
          const free = list.filter((u: any) => !u.subscription || u.subscription === 'free').length;
          const levels: Record<string, number> = { free, yangxin: 0, yiyang: 0, jiahe: 0 };
          list.forEach((u: any) => {
            if (u.subscription === 'yangxin') levels.yangxin++;
            if (u.subscription === 'yiyang') levels.yiyang++;
            if (u.subscription === 'jiahe') levels.jiahe++;
          });
          const mTotal = total || 1;
          setMembership([
            { label: '免费用户', value: Math.round((levels.free / mTotal) * 100), color: 'bg-gray-300' },
            { label: '养心会员', value: Math.round((levels.yangxin / mTotal) * 100), color: 'bg-blue-400' },
            { label: '颐养会员', value: Math.round((levels.yiyang / mTotal) * 100), color: 'bg-violet-400' },
            { label: '家和会员', value: Math.round((levels.jiahe / mTotal) * 100), color: 'bg-amber-400' },
          ]);
        }
      } catch {}

      // Audit / AI stats
      try {
        const auditRes = (await fetchAPI('/api/v1/audit/stats')) as any;
        if (auditRes && !auditRes.error) {
          const todayCalls = auditRes.today_calls ?? auditRes.todayCalls ?? auditRes.calls_today ?? 0;
          const models = auditRes.top_models ?? auditRes.topModels ?? [];
          setCards((prev) => [prev[0], prev[1], { ...prev[2], value: todayCalls.toLocaleString() }, prev[3]]);
          if (models.length > 0) {
            const maxVal = Math.max(...models.map((m: any) => m.count ?? m.value ?? 0), 1);
            setTopModels(
              models.slice(0, 5).map((m: any) => ({
                label: m.model || m.name || '未知',
                value: m.count ?? m.value ?? 0,
                max: maxVal,
                color: 'bg-violet-500',
              })),
            );
          }
        }
      } catch {}

      // Content stats
      try {
        const contentRes = (await fetchAPI('/api/v1/cms/content')) as any;
        if (contentRes && !contentRes.error) {
          const list = Array.isArray(contentRes) ? contentRes : contentRes.data || [];
          const typeCount: Record<string, number> = {};
          list.forEach((c: any) => {
            const t = c.type || c.content_type || '其他';
            typeCount[t] = (typeCount[t] || 0) + 1;
          });
          const total = list.length || 1;
          const colors = ['bg-green-400', 'bg-orange-400', 'bg-cyan-400', 'bg-pink-400', 'bg-gray-300'];
          const nameMap: Record<string, string> = {
            article: '养生文章',
            recipe: '食疗方案',
            solar_term: '节气提醒',
            exercise: '运动指导',
            video: '视频内容',
          };
          const entries = Object.entries(typeCount).sort((a, b) => b[1] - a[1]);
          setContentTypes(
            entries.slice(0, 5).map(([key, val], i) => ({
              label: nameMap[key] || key,
              value: Math.round((val / total) * 100),
              color: colors[i % colors.length],
            })),
          );
        }
      } catch {}

      // Safety stats
      try {
        const safetyRes = (await fetchAPI('/api/v1/safety/stats')) as any;
        if (safetyRes && !safetyRes.error) {
          const today = safetyRes.today ?? safetyRes.today_events ?? 0;
          setCards((prev) => [prev[0], prev[1], prev[2], { ...prev[3], value: String(today) }]);
          const trend = safetyRes.trend ?? safetyRes.weekly ?? [];
          if (trend.length > 0) {
            const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
            const maxVal = Math.max(...trend.map((t: any) => t.count ?? t.value ?? 0), 1);
            setSafetyTrend(
              trend.slice(0, 7).map((t: any) => {
                const v = t.count ?? t.value ?? 0;
                return {
                  label: t.day ? days[t.day] : t.date || t.label || '',
                  value: v,
                  max: maxVal,
                  color: v >= 10 ? 'bg-red-400' : v >= 5 ? 'bg-orange-400' : 'bg-green-400',
                };
              }),
            );
          }
        }
      } catch {}

      setLoading(false);
    }
    load();
  }, []);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">数据看板</h2>

      {loading && (
        <div className="flex items-center gap-2 text-sm text-gray-400 mb-4">
          <span className="animate-spin">⏳</span> 正在加载数据…
        </div>
      )}

      {/* Top cards */}
      <div className="grid grid-cols-4 gap-6 mb-8">
        {cards.map((c) => (
          <div key={c.label} className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className={`w-2 h-8 rounded ${c.color}`} />
              <span className="text-sm text-gray-500">{c.label}</span>
            </div>
            <div className="text-3xl font-bold">{c.value}</div>
            <div className="text-sm text-gray-400 mt-1">{c.change}</div>
          </div>
        ))}
      </div>

      {/* Row 2: donut charts */}
      <div className="grid grid-cols-2 gap-6 mb-8">
        <DonutChart data={membership} title="会员分布" />
        <DonutChart data={contentTypes} title="内容类型分布" />
      </div>

      {/* Row 3: bar charts */}
      <div className="grid grid-cols-2 gap-6">
        <BarChart data={safetyTrend} title="安全事件趋势（近7日）" />
        <BarChart data={topModels} title="AI调用 Top 模型" />
      </div>
    </div>
  );
}
