// Axe smoke for the Flutter web shells and the admin site.
//
// What axe can see
// - The HTML document: language, title, viewport, and the Flutter host element.
// - Flutter's semantics DOM (flt-semantics) after semantics are enabled: roles,
//   accessible names, and the computed style of those nodes.
// - That #app-readable-copy exists and holds the route's words. The test waits
//   on that node before scanning.
//
// What axe cannot see
// - Anything painted only on the canvas (CanvasKit or skwasm). Contrast, hit
//   targets, and focus rings that exist solely as pixels are invisible to axe.
// - The text inside #app-readable-copy. That node is aria-hidden and opacity 0
//   so screen readers stay on Flutter's semantics tree and the words are not
//   announced twice. Axe skips aria-hidden content, so it does not grade that
//   mirror. The mirror is the proof the route rendered, not the thing axe scores.
//
// This fails on serious or critical violations only. It is not a WCAG certification.
import { test, expect, type Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const cn = process.env.CN_WEB_URL || 'http://127.0.0.1:8091';
const globalWeb = process.env.GLOBAL_WEB_URL || 'http://127.0.0.1:8092';
const admin = process.env.ADMIN_URL || 'http://127.0.0.1:3018';

async function openFlutter(page: Page, origin: string, route: string) {
  // Flutter web uses a hash URL. `/#/login` is the login route; the path
  // before the hash is only the static file.
  await page.goto(`${origin}/#${route}`, { waitUntil: 'domcontentloaded' });
  await page.evaluate(async () => {
    if (!('serviceWorker' in navigator)) return;
    const regs = await navigator.serviceWorker.getRegistrations();
    await Promise.all(regs.map((reg) => reg.unregister()));
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
  });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(
    () => document.querySelector('flt-semantics-placeholder, flt-semantics, #app-readable-copy') !== null,
    null,
    { timeout: 90_000 },
  );
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder instanceof HTMLElement) placeholder.click();
  });
  await page.waitForFunction(
    () => {
      const el = document.querySelector('#app-readable-copy');
      return !!el && (el.textContent || '').trim().length > 8;
    },
    null,
    { timeout: 90_000 },
  );
}

async function expectReadable(page: Page, pattern: RegExp) {
  await expect(page.locator('#app-readable-copy')).toContainText(pattern, { timeout: 20_000 });
}

async function expectNoSeriousOrCritical(page: Page, label: string) {
  const results = await new AxeBuilder({ page }).analyze();
  const bad = results.violations.filter((v) => v.impact === 'serious' || v.impact === 'critical');
  const detail = bad.map((v) => {
    const nodes = v.nodes.slice(0, 4).map((n) => `${n.target.join(' ')} — ${n.failureSummary || ''}`).join('\n    ');
    return `${v.id} [${v.impact}] ${v.help}\n    ${nodes}`;
  }).join('\n');
  expect(bad, `${label}\n${detail}`).toEqual([]);
}

const flutterRoutes: Array<{ app: string; origin: string; route: string; text: RegExp }> = [
  { app: 'android-cn', origin: cn, route: '/', text: /开始使用/ },
  { app: 'android-cn', origin: cn, route: '/login', text: /登录/ },
  { app: 'android-cn', origin: cn, route: '/today', text: /今天|今日|聊天/ },
  { app: 'android-cn', origin: cn, route: '/subscription', text: /年|订阅|会员/ },
  { app: 'android-global', origin: globalWeb, route: '/', text: /feeling|SEASONS/i },
  { app: 'android-global', origin: globalWeb, route: '/login', text: /Sign in|Email|account/i },
  { app: 'android-global', origin: globalWeb, route: '/home', text: /Today|Wellness|Wind down/i },
  { app: 'android-global', origin: globalWeb, route: '/subscription', text: /Subscribe|year/i },
];

for (const item of flutterRoutes) {
  test(`${item.app} ${item.route} has no serious or critical axe violations`, async ({ page }) => {
    await openFlutter(page, item.origin, item.route);
    await expectReadable(page, item.text);
    await expectNoSeriousOrCritical(page, `${item.app} ${item.route}`);
  });
}

test('admin login has no serious or critical axe violations', async ({ page }) => {
  await page.goto(`${admin}/login`, { waitUntil: 'domcontentloaded' });
  await expect(page.getByRole('heading', { name: '顺时管理后台' })).toBeVisible();
  await expectNoSeriousOrCritical(page, 'admin /login');
});

test('admin home gate has no serious or critical axe violations', async ({ page }) => {
  await page.goto(`${admin}/`, { waitUntil: 'domcontentloaded' });
  await expect(page.getByText(/正在验证管理员身份|顺时管理后台|总用户数/)).toBeVisible();
  await expectNoSeriousOrCritical(page, 'admin /');
});
