'use client';

import { useEffect, useSyncExternalStore } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { isLoggedIn } from '@/lib/api';

export default function AuthGate({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const isLogin = pathname === '/login';
  const loggedIn = useSyncExternalStore(
    (onChange) => {
      window.addEventListener('storage', onChange);
      window.addEventListener('admin-auth-changed', onChange);
      return () => {
        window.removeEventListener('storage', onChange);
        window.removeEventListener('admin-auth-changed', onChange);
      };
    },
    isLoggedIn,
    () => false,
  );

  useEffect(() => {
    if (!isLogin && !loggedIn) {
      router.replace('/login');
    }
  }, [isLogin, loggedIn, router]);

  if (!isLogin && !loggedIn) {
    return <main className="min-h-screen grid place-items-center text-sm text-gray-500">正在验证管理员身份…</main>;
  }
  return children;
}
