'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI, putAPI } from '../../lib/api';

interface Flag {
  key: string;
  name: string;
  description: string;
  enabled: boolean;
  target_users?: string;
  rollout_pct?: number;
  updated_at: string;
}

export default function FlagsPage() {
  const [flags, setFlags] = useState<Flag[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadFlags(); }, []);

  async function loadFlags() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: Flag[] }>('/api/v1/flags');
      if (res?.data) setFlags(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  async function toggleFlag(key: string, current: boolean) {
    try {
      await putAPI(`/api/v1/flags/${key}`, { enabled: !current });
      loadFlags();
    } catch { alert('操作失败'); }
  }

  const defaultFlags: Flag[] = [
    { key: 'ai_companion_v2', name: 'AI伴侣V2', description: '新版AI对话界面和模型', enabled: true, rollout_pct: 100, updated_at: '2026-04-15' },
    { key: 'new_onboarding', name: '新用户引导', description: '改进的注册引导流程', enabled: true, rollout_pct: 50, updated_at: '2026-04-10' },
    { key: 'family_sharing', name: '家庭共享', description: '家庭成员内容共享功能', enabled: true, rollout_pct: 100, updated_at: '2026-04-08' },
    { key: 'dark_mode', name: '深色模式', description: '应用深色主题', enabled: false, rollout_pct: 0, updated_at: '2026-04-12' },
    { key: 'social_share', name: '社交分享', description: '微信/微博分享养生内容', enabled: false, rollout_pct: 0, updated_at: '2026-04-05' },
    { key: 'premium_content', name: '付费内容', description: '高级会员专属内容', enabled: true, rollout_pct: 100, updated_at: '2026-04-01' },
    { key: 'apple_health', name: 'Apple健康', description: 'HealthKit数据集成', enabled: false, rollout_pct: 0, updated_at: '2026-04-14' },
    { key: 'push_ai_summary', name: 'AI推送摘要', description: '智能推送养生摘要通知', enabled: true, rollout_pct: 30, updated_at: '2026-04-16' },
  ];

  const displayFlags = flags.length > 0 ? flags : defaultFlags;

  return (
    <div className="flex">
      <Sidebar active="/flags" />
      <main className="flex-1 p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">Feature Flags</h2>
        <div className="space-y-3">
          {loading ? (
            <div className="bg-white rounded-xl border p-12 text-center text-gray-400">加载中...</div>
          ) : (
            displayFlags.map((flag) => (
              <div key={flag.key} className="bg-white rounded-xl border border-gray-200 p-5 flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-1">
                    <span className="font-medium text-gray-800">{flag.name}</span>
                    <code className="text-xs bg-gray-100 px-2 py-0.5 rounded text-gray-500">{flag.key}</code>
                  </div>
                  <p className="text-sm text-gray-500">{flag.description}</p>
                  {flag.rollout_pct !== undefined && flag.rollout_pct > 0 && flag.rollout_pct < 100 && (
                    <div className="mt-2 flex items-center gap-2">
                      <div className="flex-1 max-w-32 bg-gray-100 rounded-full h-2">
                        <div className="bg-blue-500 h-full rounded-full" style={{ width: `${flag.rollout_pct}%` }} />
                      </div>
                      <span className="text-xs text-gray-400">{flag.rollout_pct}% 灰度</span>
                    </div>
                  )}
                </div>
                <button onClick={() => toggleFlag(flag.key, flag.enabled)}
                  className={`relative w-12 h-6 rounded-full transition-colors ${flag.enabled ? 'bg-blue-600' : 'bg-gray-300'}`}>
                  <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${flag.enabled ? 'left-6' : 'left-0.5'}`} />
                </button>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
