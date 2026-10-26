import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { test, expect, type Page } from '@playwright/test';

const artifacts = process.env.UI_TEST_ARTIFACT_DIR || '/opt/cursor/artifacts/ui-test';
const api = process.env.SHUNSHI_API_URL || 'http://127.0.0.1:4000';
const adminUrl = process.env.ADMIN_URL || 'http://127.0.0.1:3008';
const database = process.env.SHUNSHI_DATABASE_URL?.replace('sqlite:///', '') || '/tmp/shunshi-ui/app.db';
const python = process.env.SHUNSHI_PYTHON || '/tmp/shunshi-venv/bin/python';

fs.mkdirSync(artifacts, { recursive: true });

async function enableSemantics(page: Page) {
  await page.waitForFunction(
    () => document.querySelector('flt-semantics-placeholder, flt-semantics') !== null,
    null,
    { timeout: 90_000 },
  );
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder instanceof HTMLElement) placeholder.click();
  });
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 20_000 });
}

async function shot(page: Page, name: string) {
  const file = path.join(artifacts, name);
  await page.screenshot({ path: file, fullPage: true });
  return file;
}

async function openRoute(page: Page, route: string) {
  const usesHash = await page.evaluate(() => location.href.includes('#'));
  await page.goto(usesHash ? `/#${route}` : route);
  await page.waitForTimeout(600);
}

function see(page: Page, text: string | RegExp) {
  const pattern = text instanceof RegExp
    ? text
    : new RegExp(text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  return page
    .getByText(text)
    .or(page.getByRole('group', { name: pattern }))
    .or(page.getByRole('menuitem', { name: pattern }))
    .first();
}

async function sendLine(page: Page, text: string) {
  const composer = page.getByRole('textbox').last();
  await composer.click({ force: true });
  const current = await composer.inputValue().catch(() => '');
  if (!current.includes(text)) {
    await composer.fill(text);
  }
  const afterFill = await composer.inputValue().catch(() => '');
  if (!afterFill.includes(text)) {
    await composer.pressSequentially(text, { delay: 12 });
  }
  await page.getByRole('button', { name: '发送' }).click({ force: true });
}

async function clickText(page: Page, text: string) {
  const pattern = new RegExp(text);
  const target = page
    .getByRole('button', { name: pattern })
    .or(page.getByRole('menuitem', { name: pattern }))
    .last();
  try {
    await target.waitFor({ state: 'visible', timeout: 8_000 });
    await target.click({ force: true });
    return;
  } catch {
    const fallback = page.getByText(text).last();
    await fallback.waitFor({ state: 'visible', timeout: 12_000 });
    await fallback.click({ force: true });
  }
}

function userIdFromToken(token: string): string {
  const payload = token.split('.')[1];
  const json = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as { sub?: string };
  if (!json.sub) throw new Error('登录凭证里没有用户编号');
  return json.sub;
}

test('国内版主要流程', async ({ page }) => {
  const consoleErrors: string[] = [];
  const failedRequests: string[] = [];
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });
  page.on('pageerror', (error) => consoleErrors.push(String(error)));
  page.on('response', (response) => {
    const url = response.url();
    if (url.startsWith(api) && response.status() >= 500) {
      failedRequests.push(`${response.status()} ${url}`);
    }
  });

  await page.goto('/');
  await enableSemantics(page);
  await shot(page, '01-splash.png');

  await see(page, '开始使用').waitFor({ timeout: 20_000 });
  await shot(page, '02-onboarding-welcome.png');
  await clickText(page, '开始使用');
  await see(page, '你最关注什么？').waitFor();
  await shot(page, '03-onboarding-concerns.png');
  await clickText(page, '睡眠');
  await see(page, '准备就绪！').waitFor();
  await shot(page, '04-onboarding-ready.png');
  await clickText(page, '开始体验');
  await see(page, '今日').waitFor();
  await shot(page, '05-today.png');

  await clickText(page, '我的');
  await page.getByRole('button', { name: '设置', exact: true }).waitFor();
  await shot(page, '06-profile.png');
  await clickText(page, '设置');
  await page.getByRole('heading', { name: '设置' }).waitFor();
  await page.getByRole('group', { name: /节气提醒/ }).waitFor();
  await shot(page, '07-settings.png');
  await clickText(page, '登录');

  await see(page, '游客体验').waitFor();
  await shot(page, '08-login.png');
  await clickText(page, '游客体验');

  await see(page, '你好，怎么称呼你？').waitFor({ timeout: 20_000 });
  await shot(page, '09-profile-setup-name.png');
  const nameField = page.getByRole('textbox').last();
  await nameField.click();
  await nameField.pressSequentially('阿时');
  await clickText(page, '下一步');
  await see(page, '你的性别是？').waitFor();
  await shot(page, '10-profile-setup-gender.png');
  await clickText(page, '女');
  await clickText(page, '下一步');
  await see(page, '你出生在哪一年？').waitFor();
  await shot(page, '11-profile-setup-year.png');
  await clickText(page, '睡眠');
  await clickText(page, '下一步');
  await see(page, '平和质').waitFor();
  await shot(page, '12-profile-setup-constitution.png');
  await clickText(page, '平和质');
  await clickText(page, '完成');
  await see(page, '今日').waitFor({ timeout: 20_000 });
  await see(page, /当令|霜降/).waitFor({ timeout: 20_000 });
  await shot(page, '13-home-after-setup.png');

  await clickText(page, '聊天');
  await see(page, '你在和人工智能对话，不是真人').waitFor();
  await shot(page, '14-chat-ai-label.png');

  await sendLine(page, '今晚想早点休息，怎么安排作息？');
  await see(page, '本地演示回复').waitFor({ timeout: 20_000 });
  await shot(page, '15-chat-reply.png');

  const rawToken = await page.evaluate(() => localStorage.getItem('flutter.auth_token'));
  expect(rawToken, '登录后应写入本地凭证').toBeTruthy();
  const token = JSON.parse(rawToken as string) as string;
  execFileSync(python, [
    path.resolve(__dirname, '../seed_continuous_session.py'),
    userIdFromToken(token),
    database,
  ], { stdio: 'inherit' });

  await sendLine(page, '再帮我看一眼今天的作息');
  await see(page, '你已经连续使用超过 2 小时了').waitFor({ timeout: 20_000 });
  await expect(page.getByRole('group', { name: /本地演示回复/ })).toHaveCount(2);
  await shot(page, '16-two-hour-reminder.png');

  await sendLine(page, '六味地黄丸每次 9 克怎么吃');
  await see(page, '不要自行用药').waitFor({ timeout: 20_000 });
  await shot(page, '17-dosage-blocked.png');

  await sendLine(page, '这个方子可长期服用吗');
  await expect(page.getByRole('group', { name: /不要自行用药/ })).toHaveCount(2);
  await shot(page, '18-long-term-claim-blocked.png');

  await page.getByRole('button', { name: '更多' }).click();
  await see(page, '结束陪伴').waitFor();
  await shot(page, '19-end-companion-menu.png');
  await clickText(page, '结束陪伴');
  await see(page, '这次陪伴先到这里').waitFor();
  await shot(page, '20-companion-ended.png');

  await openRoute(page, '/membership');
  await see(page, '399').waitFor({ timeout: 20_000 });
  await expect(see(page, '888')).toBeVisible();
  await shot(page, '21-membership.png');
  await page.getByText('开通', { exact: true }).first().click();
  await see(page, '选择支付方式').waitFor({ timeout: 10_000 });
  await shot(page, '22-payment-sheet.png');
  await page.keyboard.press('Escape');

  await openRoute(page, '/about');
  await see(page, '北京艾瑞见时科技有限公司').waitFor();
  await expect(see(page, '核准后公示')).toBeVisible();
  await shot(page, '23-about-filing.png');
  await clickText(page, '隐私政策');
  await see(page, '不用于训练模型').waitFor();
  await expect(see(page, '北京艾瑞见时科技有限公司')).toBeVisible();
  await shot(page, '24-privacy-policy.png');
  await page.goBack();
  await see(page, '用户协议').waitFor();
  await clickText(page, '用户协议');
  await see(page, '北京艾瑞见时科技有限公司').waitFor();
  await shot(page, '25-terms.png');

  await openRoute(page, '/settings');
  await see(page, '游客体验').waitFor();
  await expect(page.getByText('云水禅心')).toHaveCount(0);
  await expect(page.getByText('124.5 MB')).toHaveCount(0);
  await shot(page, '26-settings-after-login.png');

  await openRoute(page, '/this-page-does-not-exist');
  await see(page, /找不到|小问题|返回/).waitFor();
  await shot(page, '27-error-page.png');

  await openRoute(page, '/login');
  await see(page, '获取验证码').waitFor();
  await clickText(page, '获取验证码');
  await page.waitForTimeout(800);
  await shot(page, '28-login-sms-error.png');

  fs.writeFileSync(
    path.join(artifacts, 'console-notes.json'),
    JSON.stringify({ consoleErrors, failedRequests }, null, 2),
  );
  expect(failedRequests, failedRequests.join('\n')).toEqual([]);
});

test('管理后台桌面', async ({ browser }) => {
  const context = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await context.newPage();
  const reachable = await page.goto(`${adminUrl}/login`).then((response) => response?.ok() ?? false).catch(() => false);
  if (!reachable) {
    test.skip(true, '管理后台没有启动');
  }
  await shot(page, '29-admin-login.png');
  await page.locator('input[name="username"], input[type="text"]').first().fill('admin');
  await page.locator('input[name="password"]').fill('ui-test-dummy-password');
  await page.getByRole('button', { name: /登录/ }).click();
  await page.waitForTimeout(1500);
  await shot(page, '30-admin-after-login.png');
  await page.goto(`${adminUrl}/subscription`);
  await page.waitForTimeout(1000);
  await shot(page, '31-admin-subscription.png');
  await context.close();
});
