'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const menuItems = [
  { href: '/', label: '仪表盘', icon: '📊' },
  { href: '/analytics', label: '数据看板', icon: '📈' },
  { href: '/users', label: '用户管理', icon: '👥' },
  { href: '/subscription', label: '会员管理', icon: '💎' },
  { href: '/content', label: '内容管理', icon: '📝' },
  { href: '/safety', label: '安全审计', icon: '🛡️' },
  { href: '/alerts', label: '告警中心', icon: '🔔' },
  { href: '/prompts', label: 'Prompt管理', icon: '🤖' },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed left-0 top-0 h-screen w-[240px] bg-white border-r border-gray-200 flex flex-col z-10">
      <div className="h-16 flex items-center px-6 border-b border-gray-200">
        <h1 className="text-lg font-bold text-gray-800">顺时管理后台</h1>
      </div>
      <nav className="flex-1 py-4">
        {menuItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-6 py-3 text-sm transition-colors ${
                isActive
                  ? 'bg-blue-50 text-blue-700 font-medium border-r-2 border-blue-700'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`}
            >
              <span className="text-base">{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
      <div className="p-4 border-t border-gray-200">
        <div className="text-xs text-gray-400">v1.0.0 · Dev Mode</div>
      </div>
    </aside>
  );
}
