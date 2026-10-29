'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';
import { asList, readError } from '@/lib/format';

interface Skill {
  skill_id?: string;
  id?: string;
  name: string;
  category?: string;
  description?: string;
  priority?: string;
  tags?: string[];
  is_active?: boolean;
  is_premium?: boolean;
}

export default function SkillsPage() {
  const [skills, setSkills] = useState<Skill[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filterCat, setFilterCat] = useState('all');

  useEffect(() => { loadSkills(); }, []);

  async function loadSkills() {
    setLoading(true);
    setError('');
    try {
      const res = await fetchAPI<unknown>('/api/v1/skills?limit=200');
      const message = readError(res);
      if (message) setError(message);
      setSkills(asList<Skill>(res).filter((item) => item?.name));
    } catch {
      setError('数据暂时读不到，请稍后刷新。');
      setSkills([]);
    }
    setLoading(false);
  }

  const categoryLabel: Record<string, string> = {
    season: '节气', constitution: '体质', exercise: '运动', diet: '饮食', tea: '茶饮', acupoint: '穴位', sleep: '睡眠',
  };
  const categories = ['all', ...new Set(skills.map((skill) => skill.category).filter(Boolean) as string[])];
  const filtered = filterCat === 'all' ? skills : skills.filter((skill) => skill.category === filterCat);

  return (
    <div className="flex min-h-screen max-w-full overflow-x-hidden bg-gray-50">
      <Sidebar active="/skills" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
          <h2 className="text-2xl font-bold text-gray-800">智能技能</h2>
          <span className="text-sm text-gray-600">{skills.length} 个技能</span>
        </div>
        {error && <div role="alert" className="mb-4 px-4 py-3 bg-red-50 text-red-700 text-sm rounded-lg">{error}</div>}
        <div className="flex gap-2 mb-6 flex-wrap">
          {categories.map((category) => (
            <button key={category} onClick={() => setFilterCat(category)}
              className={`px-3 py-2 rounded-lg text-sm ${filterCat === category ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
              {category === 'all' ? '全部' : (categoryLabel[category] || category)}
            </button>
          ))}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {loading ? (
            <div className="md:col-span-2 xl:col-span-3 text-center text-gray-600 py-12">加载中...</div>
          ) : filtered.length === 0 ? (
            <div className="md:col-span-2 xl:col-span-3 text-center text-gray-600 py-12">暂无技能</div>
          ) : (
            filtered.map((skill) => (
              <div key={skill.skill_id || skill.id || skill.name} className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-start justify-between gap-3 mb-2">
                  <span className="font-medium text-gray-800 break-words">{skill.name}</span>
                  {skill.priority && <span className="shrink-0 text-xs px-2 py-0.5 rounded bg-gray-100 text-gray-700">{skill.priority}</span>}
                </div>
                {skill.description && <p className="text-sm text-gray-600 mb-3 break-words">{skill.description}</p>}
                <div className="flex flex-wrap gap-2 text-xs text-gray-600">
                  {skill.category && <span>{categoryLabel[skill.category] || skill.category}</span>}
                  {skill.is_premium === true && <span>会员技能</span>}
                  {(skill.tags || []).map((tag) => <span key={tag} className="bg-blue-50 text-blue-800 px-2 py-0.5 rounded">{tag}</span>)}
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
