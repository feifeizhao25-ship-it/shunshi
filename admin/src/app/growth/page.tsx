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

interface SkillRow {
  name: string;
  version: string;
  description: string;
  channels: string[];
  golden_count: number;
  redteam_count: number;
}

interface SourceRow {
  source_id: string;
  title: string;
  license: string;
  tier: string;
  published_at: string;
  status: string;
}

interface AuditRow {
  id: string;
  action: string;
  decision: string;
  object_key: string;
  version: string;
}

const SOURCE_STATUS: Record<string, string> = {
  registered: '已登记',
  active: '可检索',
  candidate: '待人审',
  archived: '已归档',
};

const DRAFT_STATUS: Record<string, string> = {
  pending_human: '待人工确认',
  human_confirmed: '已人工确认',
};

export default function GrowthPage() {
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [funnel, setFunnel] = useState<Funnel | null>(null);
  const [skills, setSkills] = useState<SkillRow[]>([]);
  const [sources, setSources] = useState<SourceRow[]>([]);
  const [audit, setAudit] = useState<AuditRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [notice, setNotice] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError('');
    const [queue, funnelRes, skillRes, sourceRes, auditRes] = await Promise.all([
      fetchAPI<{ data: Draft[]; error?: string }>('/api/v1/admin/growth/queue'),
      fetchAPI<{ data: Funnel; error?: string }>('/api/v1/admin/growth/funnel'),
      fetchAPI<{ data: SkillRow[]; error?: string }>('/api/v1/admin/growth/skills'),
      fetchAPI<{ data: SourceRow[]; error?: string }>('/api/v1/admin/growth/sources'),
      fetchAPI<{ data: AuditRow[]; error?: string }>('/api/v1/admin/growth/audit'),
    ]);
    const failed = [queue, funnelRes, skillRes, sourceRes, auditRes].find((item) => item?.error);
    setDrafts(Array.isArray(queue?.data) ? queue.data : []);
    setSkills(Array.isArray(skillRes?.data) ? skillRes.data : []);
    setSources(Array.isArray(sourceRes?.data) ? sourceRes.data : []);
    setAudit(Array.isArray(auditRes?.data) ? auditRes.data : []);
    setFunnel(funnelRes?.data && !Array.isArray(funnelRes.data) ? funnelRes.data : null);
    setLoadError(failed?.error ? '增长数据没有加载出来' : '');
    setLoading(false);
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  async function confirmDraft(id: string) {
    setNotice('');
    const res = await postAPI<{ data?: { status?: string; external_posted?: boolean; published?: boolean }; error?: string }>(
      `/api/v1/admin/growth/queue/${id}/confirm`,
      {},
    );
    if (res?.error || !res?.data?.status) {
      setNotice('确认失败，稿子没有发出去。');
    } else if (res.data.external_posted || res.data.published) {
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
        {loadError ? <p className="mt-3 text-sm text-red-600">{loadError}</p> : null}
        {notice ? <p role="status" className="mt-3 text-sm text-blue-700">{notice}</p> : null}

        <section id="growth-funnel" className="mt-6">
          <h2 className="text-lg font-medium text-gray-900">漏斗</h2>
          {funnel ? (
            <>
              <div className="mt-3 grid grid-cols-2 md:grid-cols-4 gap-3">
                {[
                  ['落地', counts.landing_view || 0, 'funnel-landing'],
                  ['注册', counts.signup || 0, 'funnel-signup'],
                  ['第一次作息', counts.first_rhythm_logged || 0, 'funnel-rhythm'],
                  ['付费', counts.subscription_paid || 0, 'funnel-paid'],
                ].map(([label, value, testId]) => (
                  <div key={String(label)} className="bg-white rounded-lg border border-gray-200 p-4">
                    <div className="text-xs text-gray-400">{label}</div>
                    <div data-testid={String(testId)} className="text-xl font-semibold text-gray-900">{value}</div>
                  </div>
                ))}
              </div>
              <p className="mt-3 text-sm text-gray-500">
                规划 ARPU ¥{funnel.arpu_yuan}，预测收入 ¥{funnel.projected_revenue_yuan}
                ，带来的注册 {funnel.attributed_signups}
              </p>
            </>
          ) : (
            <p className="mt-3 text-sm text-gray-400">{loading ? '加载中' : '漏斗没有加载出来'}</p>
          )}
        </section>

        <section id="growth-skills" className="mt-8">
          <h2 className="text-lg font-medium text-gray-900">技能版本</h2>
          <div className="mt-3 bg-white rounded-lg border border-gray-200 overflow-x-auto">
            {loading ? <p className="p-4 text-sm text-gray-400">加载中</p> : null}
            {!loading && skills.length === 0 ? <p className="p-4 text-sm text-gray-400">没有读到技能</p> : null}
            {skills.length > 0 ? (
              <table className="w-full text-sm">
                <thead className="text-left text-gray-400">
                  <tr>
                    <th className="px-4 py-2 font-normal">技能</th>
                    <th className="px-4 py-2 font-normal">版本</th>
                    <th className="px-4 py-2 font-normal">渠道</th>
                    <th className="px-4 py-2 font-normal">黄金集</th>
                    <th className="px-4 py-2 font-normal">红队</th>
                  </tr>
                </thead>
                <tbody>
                  {skills.map((skill) => (
                    <tr key={skill.name} className="border-t border-gray-100">
                      <td className="px-4 py-2 text-gray-900">{skill.name}</td>
                      <td className="px-4 py-2">{skill.version}</td>
                      <td className="px-4 py-2 text-gray-500">{skill.channels.join('、')}</td>
                      <td className="px-4 py-2">{skill.golden_count}</td>
                      <td className="px-4 py-2">{skill.redteam_count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : null}
          </div>
        </section>

        <section id="growth-sources" className="mt-8">
          <h2 className="text-lg font-medium text-gray-900">知识库来源</h2>
          <div className="mt-3 bg-white rounded-lg border border-gray-200 overflow-x-auto">
            {!loading && sources.length === 0 ? <p className="p-4 text-sm text-gray-400">没有读到来源</p> : null}
            {sources.length > 0 ? (
              <table className="w-full text-sm">
                <thead className="text-left text-gray-400">
                  <tr>
                    <th className="px-4 py-2 font-normal">编号</th>
                    <th className="px-4 py-2 font-normal">标题</th>
                    <th className="px-4 py-2 font-normal">许可</th>
                    <th className="px-4 py-2 font-normal">状态</th>
                  </tr>
                </thead>
                <tbody>
                  {sources.map((source) => (
                    <tr key={source.source_id} className="border-t border-gray-100">
                      <td className="px-4 py-2 text-gray-900">{source.source_id}</td>
                      <td className="px-4 py-2">{source.title || '未命名来源'}</td>
                      <td className="px-4 py-2 text-gray-500">{source.license || '—'}</td>
                      <td className="px-4 py-2">{SOURCE_STATUS[source.status] || source.status}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : null}
          </div>
        </section>

        <section id="growth-queue" className="mt-8">
          <h2 className="text-lg font-medium text-gray-900">发布队列</h2>
          <div className="mt-3 bg-white rounded-lg border border-gray-200">
            {!loading && drafts.length === 0 ? <p className="p-4 text-sm text-gray-400">还没有待确认的草稿</p> : null}
            <ul>
              {drafts.map((draft) => (
                <li key={draft.id} className="flex items-center justify-between gap-3 px-4 py-3 border-t border-gray-100">
                  <div>
                    <div className="text-sm text-gray-900">{draft.title || '未命名草稿'}</div>
                    <div className="text-xs text-gray-400">
                      {draft.platform} · {DRAFT_STATUS[draft.status] || draft.status}
                      {draft.aigc_labeled ? ' · 已标人工智能生成' : ''}
                      {draft.external_posted ? ' · 异常：标记了已外发' : ' · 未外发'}
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
          </div>
        </section>

        <section id="growth-audit" className="mt-8">
          <h2 className="text-lg font-medium text-gray-900">审计日志</h2>
          <div className="mt-3 bg-white rounded-lg border border-gray-200 overflow-x-auto">
            {!loading && audit.length === 0 ? <p className="p-4 text-sm text-gray-400">还没有审计记录</p> : null}
            {audit.length > 0 ? (
              <table className="w-full text-sm">
                <thead className="text-left text-gray-400">
                  <tr>
                    <th className="px-4 py-2 font-normal">动作</th>
                    <th className="px-4 py-2 font-normal">决定</th>
                    <th className="px-4 py-2 font-normal">对象</th>
                  </tr>
                </thead>
                <tbody>
                  {audit.map((row) => (
                    <tr key={row.id} className="border-t border-gray-100">
                      <td className="px-4 py-2 text-gray-900">{row.action}</td>
                      <td className="px-4 py-2">{row.decision}</td>
                      <td className="px-4 py-2 text-gray-500">{row.object_key || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : null}
          </div>
        </section>
      </main>
    </div>
  );
}
