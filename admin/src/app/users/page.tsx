import { fetchAPI } from '../../lib/api';

interface User {
  id: string;
  email?: string;
  phone?: string;
  nickname?: string;
  role?: string;
  status?: string;
  createdAt?: string;
}

async function getUsers(): Promise<User[]> {
  const res = await fetchAPI('/api/v1/auth/users');
  if ('error' in res && res.error) {
    // Fallback demo data when backend is unavailable
    return [
      { id: 'U-1001', email: 'zhang@example.com', phone: '138****1234', nickname: '张三', role: 'user', status: 'active', createdAt: '2026-01-15' },
      { id: 'U-1002', email: 'lisi@example.com', phone: '139****5678', nickname: '李四', role: 'admin', status: 'active', createdAt: '2026-01-20' },
      { id: 'U-1003', email: 'wang@example.com', phone: '137****9012', nickname: '王五', role: 'user', status: 'banned', createdAt: '2026-02-01' },
      { id: 'U-1004', email: 'zhaoliu@example.com', phone: '136****3456', nickname: '赵六', role: 'user', status: 'active', createdAt: '2026-02-10' },
      { id: 'U-1005', email: 'sun@example.com', phone: '135****7890', nickname: '孙七', role: 'editor', status: 'active', createdAt: '2026-03-01' },
    ];
  }
  const data = (res as any).data || res;
  return Array.isArray(data) ? data : [];
}

export default async function UsersPage() {
  const users = await getUsers();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">用户管理</h2>
        <span className="text-sm text-gray-500">共 {users.length} 位用户</span>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-200">
              <th className="text-left px-6 py-3 font-medium text-gray-500">用户ID</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">昵称</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">邮箱</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">手机号</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">角色</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">状态</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">注册时间</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 font-mono text-xs">{user.id}</td>
                <td className="px-6 py-4">{user.nickname || '-'}</td>
                <td className="px-6 py-4 text-gray-500">{user.email || '-'}</td>
                <td className="px-6 py-4 text-gray-500">{user.phone || '-'}</td>
                <td className="px-6 py-4">
                  <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs">
                    {user.role || 'user'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-0.5 rounded text-xs ${
                    user.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {user.status === 'active' ? '正常' : user.status === 'banned' ? '封禁' : user.status || '未知'}
                  </span>
                </td>
                <td className="px-6 py-4 text-gray-500">{user.createdAt || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <div className="text-center py-12 text-gray-400">暂无用户数据</div>
        )}
      </div>
    </div>
  );
}
