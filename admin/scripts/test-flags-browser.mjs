import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE
  ? pathToFileURL(process.env.PLAYWRIGHT_MODULE).href : 'playwright');
const output = process.env.FLAGS_EVIDENCE_DIR || '/tmp/flags-evidence';
await fs.mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || undefined });
try {
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
  await page.addInitScript(() => localStorage.setItem('admin_token', 'fixture-token'));
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  let mode = 'empty', value = false, patches = 0, failSave = false;
  await page.route('**/api/v1/admin/flags**', async route => {
    if (route.request().method() === 'PATCH') {
      patches++;
      const request = route.request().postDataJSON();
      assert.equal(request.expected_updated_at, '2026-10-13T08:00:00Z');
      assert.equal(typeof request.value, 'boolean');
      if (!failSave) value = request.value;
      return route.fulfill({ status: failSave ? 409 : 200, contentType: 'application/json',
        body: JSON.stringify(failSave ? { detail: 'conflict' } : { success: true, value }) });
    }
    const data = mode === 'empty' ? [] : [
      { key: 'prompt.test.gray', description: '测试提示词灰度', value_type: 'boolean',
        value_default: value, rollout_pct: 20, whitelist_count: 0,
        updated_at: '2026-10-13T08:00:00Z', editable: true, binding: '提示词灰度配置' },
      { key: 'payment.stripe_live', description: '历史支付配置', value_type: 'boolean',
        value_default: false, rollout_pct: 0, whitelist_count: 0,
        updated_at: '', editable: false, binding: '尚未核实接入，仅供查看' },
    ];
    await route.fulfill({ status: mode === 'error' ? 503 : 200, contentType: 'application/json',
      body: JSON.stringify(mode === 'error' ? { detail: 'unavailable' } : { success: true, data }) });
  });
  await page.goto((process.env.ADMIN_TEST_URL || 'http://127.0.0.1:3318') + '/flags');
  await page.getByText('暂无已保存的功能配置', { exact: true }).waitFor();
  assert.equal(await page.getByRole('article').count(), 0);
  mode = 'error';
  await page.getByRole('button', { name: '刷新配置' }).click();
  await page.getByRole('alert').filter({ hasText: '读取失败' }).waitFor();
  await page.screenshot({ path: output + '/error.png', fullPage: true });
  mode = 'list';
  await page.getByRole('button', { name: '刷新配置' }).click();
  const toggle = page.getByRole('button', { name: '修改测试提示词灰度', exact: true });
  await toggle.waitFor();
  assert.equal(await page.getByRole('button', { name: '修改历史支付配置' }).isDisabled(), true);
  await toggle.click();
  await page.getByRole('status').filter({ hasText: '配置已保存' }).waitFor();
  await page.getByRole('button', { name: '修改测试提示词灰度', pressed: true }).waitFor();
  await page.screenshot({ path: output + '/desktop.png', fullPage: true });
  failSave = true;
  await toggle.click();
  await page.getByRole('status').filter({ hasText: '修改未确认' }).waitFor();
  await page.getByRole('button', { name: '修改测试提示词灰度', pressed: true }).waitFor();
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: output + '/mobile.png', fullPage: true });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
  assert.equal(patches, 2);
  assert.deepEqual(errors, []);
  console.log('Flags browser checks passed: true empty, error, retry, readonly binding, PATCH save, conflict preserves state, mobile layout; controlled API.');
} finally {
  await browser.close();
}
