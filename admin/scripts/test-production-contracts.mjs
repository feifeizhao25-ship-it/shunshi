import assert from 'node:assert/strict';
import fs from 'node:fs';

const api = fs.readFileSync(new URL('../src/lib/api.ts', import.meta.url), 'utf8');
const gate = fs.readFileSync(new URL('../src/app/auth-gate.tsx', import.meta.url), 'utf8');
const login = fs.readFileSync(new URL('../src/app/login/page.tsx', import.meta.url), 'utf8');

assert.ok(!api.includes('process.env.NEXT_PUBLIC_ADMIN_TOKEN'), '管理员令牌不得编译进公开前端包');
assert.ok(api.includes("localStorage.getItem('admin_token')"), '登录令牌读取契约缺失');
assert.ok(api.includes('res.status === 401'), '401 必须清理失效令牌');
assert.ok(api.includes("window.dispatchEvent(new Event('admin-auth-changed'))"), '401 必须广播认证失效事件');
assert.ok(api.includes("const API_BASE = process.env.NEXT_PUBLIC_API_URL || ''"), '管理端必须支持同源 API 代理');
assert.ok(!/['"`]https?:\/\/backend:4000/.test(api), '浏览器代码不得引用容器内部服务名');
assert.ok(gate.includes('() => false'), '服务端快照必须默认未登录，防止受保护内容闪现');
assert.ok(gate.includes("router.replace('/login')"), '未登录用户必须被重定向');
assert.ok(gate.includes("addEventListener('admin-auth-changed'"), '认证门禁必须监听令牌失效事件');
assert.ok(login.includes('/api/v1/admin/auth/login'), '登录页必须调用真实管理员登录端点');
assert.ok(login.includes('登录失败') && login.includes('网络错误，请稍后重试'), '登录错误必须使用易懂中文');

console.log('Admin production contracts passed');
