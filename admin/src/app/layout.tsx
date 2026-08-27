import type { Metadata } from 'next';
import './globals.css';
import AuthGate from './auth-gate';

export const metadata: Metadata = {
  title: '顺时 Admin - 管理后台',
  description: '顺时(SEASONS) 中医养生应用管理后台',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body className="bg-gray-50 min-h-screen">
        <AuthGate>{children}</AuthGate>
      </body>
    </html>
  );
}
