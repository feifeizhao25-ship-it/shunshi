import type { Metadata } from 'next';
import './globals.css';
import Sidebar from './sidebar';

export const metadata: Metadata = {
  title: '顺时管理后台',
  description: '顺时 Admin Dashboard',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body className="bg-gray-50 text-gray-900">
        <div className="flex min-h-screen">
          <Sidebar />
          <main className="flex-1 p-6 ml-[240px]">{children}</main>
        </div>
      </body>
    </html>
  );
}
