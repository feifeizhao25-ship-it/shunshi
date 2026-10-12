import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE
  ? pathToFileURL(process.env.PLAYWRIGHT_MODULE).href : 'playwright');
const base = process.env.ADMIN_TEST_URL || 'http://127.0.0.1:3318';
const output = process.env.ADMIN_EVIDENCE_DIR || '/tmp/admin-security-evidence';
await fs.mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || undefined });
try {
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(base + '/login');
  await page.evaluate(() => localStorage.setItem('admin_token', 'controlled-fixture-token'));
  let success = false, requests = 0;
  await page.route('**/api/v1/admin/auth/verify', route => route.fulfill({
    contentType: 'application/json', body: JSON.stringify({ valid: false, username: '' }),
  }));
  await page.route('**/api/v1/admin/auth/change-password', async route => {
    requests++;
    assert.deepEqual(route.request().postDataJSON(), {
      old_password: 'old-test-password-123', new_password: 'new-test-password-456',
    });
    await route.fulfill({
      status: success ? 200 : 503, contentType: 'application/json',
      body: JSON.stringify(success ? { success: true } : { detail: 'fixture unavailable' }),
    });
  });
  await page.goto(base + '/account');
  await page.getByRole('heading', { name: '登录安全' }).waitFor();
  await page.screenshot({ path: output + '/desktop.png', fullPage: true });
  await page.getByLabel('当前密码', { exact: true }).fill('old-test-password-123');
  await page.getByLabel('新密码（至少 12 个字符）', { exact: true }).fill('new-test-password-456');
  await page.getByLabel('再次输入新密码', { exact: true }).fill('different-test-password');
  await page.getByRole('button', { name: '修改密码并退出', exact: true }).click();
  await page.getByRole('alert').filter({ hasText: '两次输入的新密码不一致' }).waitFor();
  assert.equal(requests, 0);
  await page.getByLabel('再次输入新密码', { exact: true }).fill('new-test-password-456');
  await page.getByRole('button', { name: '修改密码并退出', exact: true }).click();
  await page.getByRole('alert').filter({ hasText: '修改未完成' }).waitFor();
  assert.ok(await page.evaluate(() => localStorage.getItem('admin_token')));
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByLabel('当前密码', { exact: true }).fill('');
  await page.getByLabel('新密码（至少 12 个字符）', { exact: true }).fill('');
  await page.getByLabel('再次输入新密码', { exact: true }).fill('');
  await page.screenshot({ path: output + '/mobile-error.png', fullPage: true });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  await page.getByLabel('当前密码', { exact: true }).fill('old-test-password-123');
  await page.getByLabel('新密码（至少 12 个字符）', { exact: true }).fill('new-test-password-456');
  await page.getByLabel('再次输入新密码', { exact: true }).fill('new-test-password-456');
  success = true;
  await page.getByRole('button', { name: '修改密码并退出', exact: true }).click();
  await page.waitForURL('**/login?passwordChanged=1');
  await page.getByRole('status').filter({ hasText: '密码已修改' }).waitFor();
  assert.equal(await page.evaluate(() => localStorage.getItem('admin_token')), null);
  assert.equal(requests, 2);
  assert.deepEqual(errors, []);
  await page.screenshot({ path: output + '/success-login.png', fullPage: true });
  console.log('Admin security browser checks passed: mismatch/no request, failure/no success, retry, confirmed logout, mobile layout; controlled API.');
} finally {
  await browser.close();
}
