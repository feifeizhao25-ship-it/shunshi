'use client';

import { useState, useEffect } from 'react';
import Sidebar from '../sidebar';
import { fetchAPI } from '../../lib/api';

interface Skill {
  id: string;
  name: string;
  category: string;
  description: string;
  is_active: boolean;
  usage_count: number;
  avg_rating: number;
  version: string;
}

export default function SkillsPage() {
  const [skills, setSkills] = useState<Skill[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterCat, setFilterCat] = useState('all');

  useEffect(() => { loadSkills(); }, []);

  async function loadSkills() {
    setLoading(true);
    try {
      const res = await fetchAPI<{ data: Skill[] }>('/api/v1/skills?limit=200');
      if (res?.data) setSkills(Array.isArray(res.data) ? res.data : []);
    } catch { /* empty */ }
    setLoading(false);
  }

  const categories = ['all', ...new Set(skills.map((s) => s.category))];
  const filtered = filterCat === 'all' ? skills : skills.filter((s) => s.category === filterCat);

  return (
    <div className="flex">
      <Sidebar active="/skills" />
      <main className="flex-1 p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-800">AI Skills</h2>
          <span className="text-sm text-gray-400">{skills.length} 个 Skills</span>
        </div>
        <div className="flex gap-2 mb-6 flex-wrap">
          {categories.map((c) => (
            <button key={c} onClick={() => setFilterCat(c)}
              className={`px-3 py-2 rounded-lg text-sm ${filterCat === c ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600'}`}>
              {c === 'all' ? '全部' : c}
            </button>
          ))}
        </div>
        <div className="grid grid-cols-3 gap-4">
          {loading ? (
            <div className="col-span-3 text-center text-gray-400 py-12">加载中...</div>
          ) : filtered.length === 0 ? (
            <div className="col-span-3 text-center text-gray-400 py-12">暂无Skills</div>
          ) : (
            filtered.map((skill) => (
              <div key={skill.id} className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium text-gray-800">{skill.name}</span>
                  <span className={`text-xs px-2 py-0.5 rounded ${skill.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {skill.is_active ? '启用' : '禁用'}
                  </span>
                </div>
                <p className="text-sm text-gray-500 mb-3 line-clamp-2">{skill.description}</p>
                <div className="flex gap-4 text-xs text-gray-400">
                  <span>{skill.category}</span>
                  <span>v{skill.version}</span>
                  <span>使用 {skill.usage_count} 次</span>
                  {skill.avg_rating > 0 && <span>⭐ {skill.avg_rating.toFixed(1)}</span>}
                </div>
              </div>
            ))
          )}
        </div>
      </main>
    </div>
  );
}
