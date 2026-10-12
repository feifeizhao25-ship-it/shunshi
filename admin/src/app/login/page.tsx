'use client';

import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { setAdminToken, fetchAPI } from '@/lib/api';

function PasswordChangedNotice() {
  const params = useSearchParams();
  return params.get('passwordChanged') === '1'
    ? <p role="status" className="text-green-800 text-center">密码已修改，请使用新密码登录。</p>
    : null;
}

export default function LoginPage() {
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // 如果已登录，重定向到首页
  useEffect(() => {
    const checkAuth = async () => {
      const res = await fetchAPI('/api/v1/admin/auth/verify');
      if (res?.valid) {
        router.replace('/');
      }
    };
    checkAuth();
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetchAPI('/api/v1/admin/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });

      if (res?.success && res.token) {
        setAdminToken(res.token);
        router.replace('/');
      } else {
        setError(res?.message || '登录失败');
      }
    } catch {
      setError('网络错误，请稍后重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow-lg">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            顺时管理后台
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            管理后台登录
          </p>
        </div>
        <Suspense fallback={null}><PasswordChangedNotice /></Suspense>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div>
            <label htmlFor="username" className="block mb-2">管理员账号</label>
            <input id="username" name="username" autoComplete="username" required maxLength={100}
              value={username} onChange={event => setUsername(event.target.value)}
              className="w-full border rounded px-3 py-2" />
          </div>
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="password" className="sr-only">
                密码
              </label>
              <input
                id="password"
                name="password"
                autoComplete="current-password"
                maxLength={1024}
                type="password"
                required
                className="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="请输入管理员密码"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          {error && (
            <div className="text-red-500 text-sm text-center">{error}</div>
          )}

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? '登录中...' : '登录'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
