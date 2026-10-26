import fs from 'node:fs';
import path from 'node:path';
import { expect, test, type Page } from '@playwright/test';

const artifacts = process.env.UI_TEST_ARTIFACT_DIR || '/opt/cursor/artifacts';
const api = process.env.SHUNSHI_API_URL || 'http://127.0.0.1:4000';
const adminUrl = process.env.ADMIN_URL || 'http://127.0.0.1:3008';

const PROTECTED = [
  '/api/v1/admin/growth/skills',
  '/api/v1/admin/growth/sources',
  '/api/v1/admin/growth/queue',
  '/api/v1/admin/growth/audit',
  '/api/v1/admin/growth/funnel',
];

fs.mkdirSync(artifacts, { recursive: true });

async function shot(page: Page, name: string, selector?: string) {
  const file = path.join(artifacts, name);
  if (selector) {
    const target = page.locator(selector);
    await target.scrollIntoViewIfNeeded();
    await target.screenshot({ path: file });
    return;
  }
  await page.screenshot({ path: file, fullPage: true });
}

test('增长后台：未登录拦截，登录后看技能、来源、漏斗、队列和审计', async ({ browser, request }) => {
  for (const route of PROTECTED) {
    const response = await request.get(`${api}${route}`);
    expect(response.status(), route).toBe(401);
  }

  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();
  const growthStatuses: number[] = [];
  page.on('response', (response) => {
    if (response.url().includes('/api/v1/admin/growth/')) growthStatuses.push(response.status());
  });

  const reachable = await page.goto(`${adminUrl}/growth`).then((response) => response?.ok() ?? false).catch(() => false);
  if (!reachable) test.skip(true, '管理后台没有启动');
  await page.getByRole('heading', { name: '顺时管理后台' }).waitFor();
  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByRole('heading', { name: '增长草稿' })).toHaveCount(0);
  await shot(page, 'growth-01.png');

  await page.locator('input[name="username"]').fill('admin');
  await page.locator('input[name="password"]').fill('ui-test-dummy-password');
  await page.getByRole('button', { name: '登录' }).click();
  await page.getByText('暂无活跃告警').waitFor();
  const token = await page.evaluate(() => localStorage.getItem('admin_token'));
  expect(token).toBeTruthy();
  await shot(page, 'growth-02.png');

  const headers = { 'X-Admin-Token': token as string, 'Content-Type': 'application/json' };
  const seeded = await request.post(`${api}/api/v1/admin/growth/cycle`, {
    headers,
    data: {
      proposals: [
        { skill_name: 'zhihu-answer', channel: '知乎', topic: '立夏', angle: '早睡' },
        {
          kind: 'rag',
          source_id: 'B20',
          source_text: '界面测试用的作息备忘：晚上提前安静下来。',
          license: 'internal-summary',
          tier: 'papers',
          published_at: '2026-10-01',
        },
      ],
    },
  });
  expect(seeded.ok(), await seeded.text()).toBeTruthy();
  const landing = await request.post(`${api}/api/v1/growth/events`, {
    data: { event_type: 'landing_view', anonymous_id: 'growth-ui' },
  });
  expect(landing.ok()).toBeTruthy();

  await page.getByRole('link', { name: '增长草稿' }).click();
  await page.getByRole('heading', { name: '技能版本' }).waitFor();
  const skills = page.locator('#growth-skills');
  await expect(skills.getByRole('cell', { name: 'xhs-note', exact: true })).toBeVisible();
  await expect(skills.getByRole('cell', { name: '0.1.0', exact: true }).first()).toBeVisible();
  await expect(skills.getByRole('cell', { name: 'zhihu-answer', exact: true })).toBeVisible();
  await shot(page, 'growth-03.png', '#growth-skills');

  const sources = page.locator('#growth-sources');
  await expect(sources.getByRole('cell', { name: 'A01', exact: true })).toBeVisible();
  await expect(sources.getByText('生成合成内容需要显式标识')).toBeVisible();
  await expect(sources.getByRole('cell', { name: 'B20', exact: true })).toBeVisible();
  await expect(sources.getByText('待人审').first()).toBeVisible();
  await shot(page, 'growth-04.png', '#growth-sources');

  await expect(page.getByText('规划 ARPU ¥600')).toBeVisible();
  expect(Number(await page.getByTestId('funnel-landing').innerText())).toBeGreaterThan(0);
  await shot(page, 'growth-05.png', '#growth-funnel');

  const draft = page.locator('#growth-queue li', { hasText: '立夏今晚提前入睡' }).first();
  await expect(draft).toContainText('未外发');
  await shot(page, 'growth-06.png', '#growth-queue');

  await draft.getByRole('button', { name: '人工确认' }).click();
  await expect(page.getByRole('status')).toContainText('没有发到站外');
  await expect(draft).toContainText('已人工确认');
  await expect(draft).toContainText('未外发');
  await expect(draft.getByRole('button', { name: '人工确认' })).toBeDisabled();
  await expect(page.getByText('异常：标记了已外发')).toHaveCount(0);
  await shot(page, 'growth-07.png', '#growth-queue');

  await expect(page.locator('#growth-audit').getByRole('cell', { name: 'human_confirm', exact: true }).first()).toBeVisible();
  await shot(page, 'growth-08.png', '#growth-audit');
  await shot(page, 'growth-09.png');

  expect(growthStatuses.length).toBeGreaterThan(0);
  expect(growthStatuses, growthStatuses.join(',')).not.toContain(401);
  expect(growthStatuses, growthStatuses.join(',')).not.toContain(404);
  await context.close();
});
