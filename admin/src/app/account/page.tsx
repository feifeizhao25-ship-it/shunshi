'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '../sidebar';
import { clearAdminToken, fetchAPI } from '@/lib/api';

export default function AccountPage() {
  const router = useRouter();
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (saving) return;
    if (newPassword !== confirmPassword) {
      setMessage('两次输入的新密码不一致');
      return;
    }
    if (oldPassword === newPassword) {
      setMessage('新密码不能与旧密码相同');
      return;
    }
    setSaving(true);
    setMessage('');
    try {
      const result = await fetchAPI<{ success?: boolean; error?: unknown }>(
        '/api/v1/admin/auth/change-password',
        { method: 'POST', body: JSON.stringify({ old_password: oldPassword, new_password: newPassword }) },
      );
      if (result.success !== true || result.error) {
        setMessage('修改未完成，请检查旧密码或网络后重试');
        return;
      }
      setOldPassword('');
      setNewPassword('');
      setConfirmPassword('');
      clearAdminToken();
      router.replace('/login?passwordChanged=1');
    } catch {
      setMessage('修改未确认，请重新登录核对；不要继续使用旧会话');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="flex">
      <Sidebar active="/account" />
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <h2 className="text-2xl font-bold mb-4">登录安全</h2>
        <p className="text-sm text-gray-600 mb-6">修改后所有管理员会话将退出，需要使用新密码重新登录。</p>
        <form onSubmit={submit} className="max-w-lg bg-white border rounded-xl p-5 space-y-5">
          <div>
            <label htmlFor="old-password" className="block mb-2">当前密码</label>
            <input id="old-password" type="password" autoComplete="current-password" required maxLength={1024}
              disabled={saving} value={oldPassword} onChange={e => setOldPassword(e.target.value)}
              className="w-full border rounded p-3" />
          </div>
          <div>
            <label htmlFor="new-password" className="block mb-2">新密码（至少 12 个字符）</label>
            <input id="new-password" type="password" autoComplete="new-password" required minLength={12} maxLength={1024}
              disabled={saving} value={newPassword} onChange={e => setNewPassword(e.target.value)}
              className="w-full border rounded p-3" />
          </div>
          <div>
            <label htmlFor="confirm-password" className="block mb-2">再次输入新密码</label>
            <input id="confirm-password" type="password" autoComplete="new-password" required minLength={12} maxLength={1024}
              disabled={saving} value={confirmPassword} onChange={e => setConfirmPassword(e.target.value)}
              className="w-full border rounded p-3" />
          </div>
          {message && <p role="alert" className="text-red-700">{message}</p>}
          <button type="submit" disabled={saving} className="bg-blue-700 text-white px-4 py-3 rounded disabled:opacity-50">
            {saving ? '正在修改…' : '修改密码并退出'}
          </button>
        </form>
      </main>
    </div>
  );
}
