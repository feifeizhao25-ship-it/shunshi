'use client';

import { useEffect, useState } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface Flag {
  key: string;
  description: string;
  value_type: string;
  value_default: unknown;
  rollout_pct: number;
  whitelist_count: number;
  updated_at: string;
  editable: boolean;
  binding: string;
}

export default function FlagsPage() {
  const [flags, setFlags] = useState<Flag[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [message, setMessage] = useState('');

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setLoading(true);
      setError('');
      setFlags([]);
      try {
        const result = await fetchAPI<{ success?: boolean; data?: Flag[]; error?: unknown }>(
          '/api/v1/admin/flags', { signal: controller.signal },
        );
        if (controller.signal.aborted) return;
        if (result.success !== true || result.error || !Array.isArray(result.data)) throw new Error();
        setFlags(result.data);
      } catch {
        if (!controller.signal.aborted) setError('读取失败，请检查管理员登录状态和网络后重试');
      } finally {
        if (!controller.signal.aborted) setLoading(false);
      }
    }
    void load();
    return () => controller.abort();
  }, [attempt]);

  async function toggle(flag: Flag) {
    if (saving || loading) return;
    setSaving(true);
    setMessage('');
    try {
      const value = flag.value_default !== true;
      const result = await fetchAPI<{ success?: boolean; value?: boolean; error?: unknown }>(
        '/api/v1/admin/flags/' + encodeURIComponent(flag.key),
        { method: 'PATCH', body: JSON.stringify({ value, expected_updated_at: flag.updated_at }) },
      );
      setMessage(result.success === true && !result.error && result.value === value
        ? '配置已保存。实际使用仍取决于灰度比例、白名单和可用提示词版本。'
        : '修改未确认，可能存在配置冲突或白名单限制，请刷新核对。');
    } catch {
      setMessage('修改结果未确认，请刷新核对。');
    } finally {
      setSaving(false);
      setAttempt(value => value + 1);
    }
  }

  return (
    <div className="flex">
      <Sidebar active="/flags" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold mb-4">功能开关</h2>
        <p className="text-gray-600 mb-4">仅展示已保存配置。当前只支持提示词灰度开关；保存配置不等于新功能已经上线。</p>
        <button disabled={loading || saving} onClick={() => setAttempt(value => value + 1)}
          className="border rounded px-4 py-2 mb-4 disabled:opacity-50">刷新配置</button>
        {message && <p role="status" className="mb-4">{message}</p>}
        {loading ? <p>正在读取…</p> : error ? <p role="alert">{error}</p>
          : flags.length === 0 ? <p>暂无已保存的功能配置</p>
          : <div className="space-y-4">{flags.map(flag => (
            <article key={flag.key} className="bg-white border rounded-xl p-5">
              <h3 className="font-bold">{flag.description || '未填写说明的配置'}</h3>
              <p className="text-sm break-all text-gray-600 mt-2">{flag.key}</p>
              <p className="text-sm mt-2">{flag.binding}</p>
              <p className="text-sm mt-2">覆盖比例：{flag.rollout_pct}% · 白名单：{flag.whitelist_count} 人</p>
              <p className="text-sm break-all mt-2">更新时间：{flag.updated_at || '暂无记录'}</p>
              {flag.value_type === 'boolean' ? (
                <button disabled={!flag.editable || saving || loading}
                  aria-label={`修改${flag.description || flag.key}`}
                  aria-pressed={flag.value_default === true}
                  onClick={() => toggle(flag)} className="border rounded px-4 py-2 mt-4 disabled:opacity-50">
                  默认配置：{flag.value_default === true ? '开启' : '关闭'}
                </button>
              ) : <p className="mt-4">此类型配置仅供查看</p>}
            </article>
          ))}</div>}
      </main>
    </div>
  );
}
