import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { pathToFileURL } from 'node:url';

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE
  ? pathToFileURL(process.env.PLAYWRIGHT_MODULE).href : 'playwright');
const base = process.env.ADMIN_TEST_URL || 'http://127.0.0.1:3318';
const output = process.env.FAMILY_EVIDENCE_DIR || '/tmp/admin-family-evidence';
await fs.mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || undefined });
try {
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.addInitScript(() => localStorage.setItem('admin_token', 'browser-fixture'));
  let fail = false;
  const requested = [];
  await page.route('**/api/v1/admin/families?*', async route => {
    const url = new URL(route.request().url());
    requested.push(url.pathname + url.search);
    const current = Number(url.searchParams.get('page'));
    await route.fulfill({
      status: fail ? 503 : 200,
      contentType: 'application/json',
      body: JSON.stringify(fail ? { detail: 'fixture failure' } : {
        success: true, total: 21, page: current, page_size: 20,
        data: [{
          id: String(current), name: current === 1 ? '测试家庭甲' : '测试家庭乙',
          record_count: 3, account_count: 2, updated_at: '2026-10-12 09:00:00',
        }],
      }),
    });
  });
  await page.goto(base + '/family');
  await page.getByRole('cell', { name: '测试家庭甲', exact: true }).waitFor();
  await page.screenshot({ path: output + '/desktop.png', fullPage: true });
  await page.getByRole('button', { name: '下一页', exact: true }).click();
  await page.getByRole('cell', { name: '测试家庭乙', exact: true }).waitFor();
  assert.equal(await page.getByRole('button', { name: '下一页', exact: true }).isDisabled(), true);
  await page.getByRole('button', { name: '上一页', exact: true }).click();
  await page.getByRole('cell', { name: '测试家庭甲', exact: true }).waitFor();
  fail = true;
  await page.getByRole('button', { name: '刷新', exact: true }).click();
  await page.getByRole('alert').waitFor();
  assert.equal(await page.getByText('暂无家庭记录', { exact: true }).count(), 0);
  await page.screenshot({ path: output + '/error.png', fullPage: true });
  fail = false;
  await page.getByRole('button', { name: '重新读取', exact: true }).click();
  await page.getByRole('cell', { name: '测试家庭甲', exact: true }).waitFor();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.getByRole('article').waitFor({ state: 'visible' });
  await page.screenshot({ path: output + '/mobile.png', fullPage: true });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  await page.evaluate(() => {
    localStorage.removeItem('admin_token');
    window.dispatchEvent(new Event('admin-auth-changed'));
  });
  await page.waitForURL('**/login');
  const anonymous = await browser.newPage();
  await anonymous.goto(base + '/family');
  await anonymous.waitForURL('**/login');
  assert.equal(await anonymous.getByRole('heading', { name: '家庭记录管理' }).count(), 0);
  await anonymous.close();
  assert.deepEqual(errors, []);
  assert.ok(requested.some(url => url.includes('page=2')));
  console.log('Family browser checks passed: pagination, error, retry, mobile width, returning/anonymous/expired auth; fixture API.');
} finally {
  await browser.close();
}
