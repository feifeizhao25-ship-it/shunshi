'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { clearAdminToken, fetchAPI } from '@/lib/api';

const navItems = [
  { href: '/account', label: '登录安全', icon: '🔐' },
  { href: '/', label: '仪表盘', icon: '📊' },
  { href: '/users', label: '用户管理', icon: '👥' },
  { href: '/content', label: '内容管理', icon: '📝' },
  { href: '/analytics', label: '数据分析', icon: '📈' },
  { href: '/subscription', label: '订阅管理', icon: '💎' },
  { href: '/prompts', label: '提示词管理', icon: '🤖' },
  { href: '/llm-audit', label: '模型调用审计', icon: '🔍' },
  { href: '/safety', label: '安全中心', icon: '🛡️' },
  { href: '/alerts', label: '告警管理', icon: '🔔' },
  { href: '/flags', label: '功能开关', icon: '🚩' },
  { href: '/audit', label: '审计日志', icon: '📋' },
  { href: '/models', label: '模型管理', icon: '🧠' },
  { href: '/skills', label: '智能技能', icon: '⚡' },
  { href: '/constitution', label: '体质管理', icon: '🌿' },
  { href: '/solar-terms', label: '节气管理', icon: '🌙' },
  { href: '/family', label: '家庭管理', icon: '👨‍👩‍👧‍👦' },
  { href: '/rag', label: '知识库', icon: '📚' },
  { href: '/growth', label: '增长草稿', icon: '📣' },
];

export default function Sidebar({ active }: { active?: string }) {
  const router = useRouter();

  const handleLogout = async () => {
    await fetchAPI('/api/v1/admin/auth/logout', { method: 'POST' });
    clearAdminToken();
    router.push('/login');
  };

  return (
    <aside className="w-16 md:w-64 shrink-0 bg-white border-r border-gray-200 min-h-screen flex flex-col">
      <div className="px-2 md:px-6 py-5 border-b border-gray-200">
        <h1 className="text-xl font-bold text-gray-800">顺时</h1>
        <p className="hidden md:block text-xs text-gray-400 mt-1">国内版管理后台</p>
      </div>
      <nav className="flex-1 p-1 md:p-4 space-y-1 overflow-y-auto">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            aria-label={item.label}
            title={item.label}
            className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-colors ${
              active === item.href
                ? 'bg-blue-50 text-blue-700 font-medium'
                : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
            }`}
          >
            <span className="text-base">{item.icon}</span>
            <span className="hidden md:inline">{item.label}</span>
          </Link>
        ))}
      </nav>
      <div className="px-1 md:px-4 py-4 border-t border-gray-200 space-y-2">
        <button
          onClick={handleLogout}
          aria-label="退出登录"
          title="退出登录"
          className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm text-red-600 hover:bg-red-50 transition-colors"
        >
          <span>🚪</span>
          <span className="hidden md:inline">退出登录</span>
        </button>
        <div className="hidden md:block text-xs text-gray-400 text-center">
          接口：{process.env.NEXT_PUBLIC_API_URL || '同源安全代理'}
        </div>
      </div>
    </aside>
  );
}
