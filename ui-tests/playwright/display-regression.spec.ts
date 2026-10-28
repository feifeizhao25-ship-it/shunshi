import { expect, test, devices, type Page } from '@playwright/test';
import { chromium, webkit } from 'playwright';

const adminUrl = process.env.ADMIN_URL || 'http://127.0.0.1:3008';
const androidWeb = process.env.ANDROID_WEB_URL || 'http://127.0.0.1:8090';
const iosWeb = process.env.IOS_WEB_URL || 'http://127.0.0.1:8091';

const profiles = [
  { id: 'android-pixel-7', engine: 'chromium' as const, device: devices['Pixel 7'] },
  { id: 'android-galaxy-s24', engine: 'chromium' as const, device: devices['Galaxy S24'] },
  { id: 'ios-iphone-15-pro', engine: 'webkit' as const, device: devices['iPhone 15 Pro'] },
  { id: 'ios-iphone-se', engine: 'webkit' as const, device: devices['iPhone SE (3rd gen)'] },
  { id: 'ios-ipad', engine: 'webkit' as const, device: devices['iPad (gen 11)'] },
];

async function overflow(page: Page, requireText = true) {
  const box = await page.evaluate(() => ({
    scroll: document.documentElement.scrollWidth,
    client: document.documentElement.clientWidth,
    text: document.body.innerText,
    canvas: document.querySelectorAll('canvas, flutter-view, flt-glass-pane').length,
  }));
  expect(box.scroll, '页面出现横向溢出').toBeLessThanOrEqual(box.client + 1);
  if (requireText) expect(box.text.trim().length, '页面是空白').toBeGreaterThan(0);
  else expect(box.canvas, '页面没有画出来').toBeGreaterThan(0);
  return box.text;
}

test('安卓 Chromium 与苹果 WebKit 上管理后台不溢出、不编造数据', async () => {
  test.setTimeout(600_000);
  for (const profile of profiles) {
    const browser = profile.engine === 'webkit'
      ? await webkit.launch()
      : await chromium.launch({
          channel: 'chrome',
          args: ['--no-sandbox', '--disable-dev-shm-usage', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'],
        });
    const context = await browser.newContext({ ...profile.device });
    const page = await context.newPage();
    const errors: string[] = [];
    page.on('pageerror', (error) => {
      const text = String(error);
      if (text.includes('__nextjs') || text.includes('access control checks')) return;
      errors.push(text);
    });
    const reachable = await page.goto(`${adminUrl}/login`).then((response) => response?.ok() ?? false).catch(() => false);
    if (!reachable) {
      await browser.close();
      test.skip(true, '管理后台没有启动');
    }
    await expect(page.getByRole('heading', { name: '顺时管理后台' })).toBeVisible();
    const fontSize = await page.locator('input[name="password"]').evaluate((el) => getComputedStyle(el).fontSize);
    expect(Number.parseFloat(fontSize), `${profile.id} 输入框过小会触发 Safari 放大`).toBeGreaterThanOrEqual(16);
    await overflow(page);
    await page.locator('input[name="username"]').fill('admin');
    await page.locator('input[name="password"]').fill('ui-test-dummy-password');
    await page.getByRole('button', { name: '登录' }).click();
    await expect(page.getByRole('heading', { name: '仪表盘' })).toBeVisible();
    for (const [route, heading, needle] of [
      ['/models', '模型管理', 'DeepSeek'],
      ['/analytics', '数据分析', '日活跃'],
      ['/solar-terms', '节气管理', '立春'],
      ['/skills', '智能技能', '当前节气检测'],
      ['/safety', '安全中心', '不显示综合评分'],
      ['/constitution', '体质管理', '不展示示例百分比'],
      ['/alerts', '告警管理', '严重'],
    ] as const) {
      await page.goto(`${adminUrl}${route}`);
      await expect(page.getByRole('heading', { name: heading })).toBeVisible();
      await page.getByText('加载中').first().waitFor({ state: 'hidden', timeout: 15_000 }).catch(() => undefined);
      const text = await overflow(page);
      expect(text, profile.id).toContain(needle);
      expect(text).not.toContain('GPT-4o');
      expect(text).not.toContain('体质测试');
      expect(text).not.toMatch(/安全评分\s*\n?\s*87/);
    }
    expect(errors, errors.join('\n')).toEqual([]);
    await browser.close();
  }
});

async function checkFlutter(page: Page, base: string) {
  await page.goto(base + '/', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('flutter-view, flt-glass-pane, canvas', { timeout: 60_000 });
  await page.waitForTimeout(2500);
  const viewport = await page.locator('meta[name="viewport"]').first().getAttribute('content');
  expect(viewport || '', '刘海机需要 viewport-fit=cover').toContain('viewport-fit=cover');
  await page.evaluate(() => {
    localStorage.setItem('flutter.onboarding_completed', 'true');
    localStorage.setItem('flutter.profile_completed', 'true');
  });
  await page.goto(`${base}/#/today`, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);
  await overflow(page, false);
}

test('安卓 H5 与苹果 WebKit 上国内网页保留安全区视口', async () => {
  test.setTimeout(180_000);
  const android = await chromium.launch({
    channel: 'chrome',
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'],
  });
  const pixel = await android.newContext({ ...devices['Pixel 7'] });
  const pixelPage = await pixel.newPage();
  const androidUp = await pixelPage.goto(androidWeb).then((r) => r?.ok() ?? false).catch(() => false);
  if (androidUp) await checkFlutter(pixelPage, androidWeb);
  await android.close();

  const apple = await webkit.launch();
  const phone = await apple.newContext({ ...devices['iPhone 15 Pro'] });
  const phonePage = await phone.newPage();
  const iosUp = await phonePage.goto(iosWeb).then((r) => r?.ok() ?? false).catch(() => false);
  if (iosUp) await checkFlutter(phonePage, iosWeb);
  await apple.close();
  if (!androidUp && !iosUp) test.skip(true, '国内网页没有启动');
});
