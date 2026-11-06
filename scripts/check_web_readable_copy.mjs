// Proves CanvasKit Flutter web exposes on-screen copy to document.body.innerText.
// Usage: node scripts/check_web_readable_copy.mjs http://127.0.0.1:8091 cn
//        node scripts/check_web_readable_copy.mjs http://127.0.0.1:8092 global
// Does not claim the browser played audio or captured a microphone.
import puppeteer from 'puppeteer-core';

const base = (process.argv[2] || '').replace(/\/$/, '');
const edition = process.argv[3] || 'cn';
if (!base) {
  console.error('missing base url');
  process.exit(2);
}

const chrome = process.env.CHROME_PATH || '/usr/local/bin/google-chrome';
const browser = await puppeteer.launch({
  executablePath: chrome,
  headless: 'new',
  args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'],
});

const expectText = async (page, needles, timeout = 45000) => {
  const started = Date.now();
  let last = '';
  while (Date.now() - started < timeout) {
    last = await page.evaluate(() => {
      const host = document.getElementById('app-readable-copy');
      return {
        body: document.body ? document.body.innerText : '',
        host: host ? host.innerText : '',
        hostText: host ? (host.textContent || '') : '',
      };
    });
    const blob = `${last.body}\n${last.host}\n${last.hostText}`;
    if (needles.every((n) => blob.includes(n))) {
      return last;
    }
    await new Promise((r) => setTimeout(r, 400));
  }
  throw new Error(`missing ${JSON.stringify(needles)} after ${timeout}ms. body_len=${last.body.length} host_len=${(last.host || '').length} sample=${(last.body || last.host || '').slice(0, 240)}`);
};

try {
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });
  const guest = edition === 'global'
    ? ['SEASONS', 'been feeling', 'Continue']
    : ['顺时', '顺应天时，养身心', '开始使用'];
  const today = edition === 'global'
    ? ['Read today', 'Speak']
    : ['朗读今日', '用语音说'];
  const chat = edition === 'global'
    ? ['Read this', 'Speak']
    : ['朗读这段', '用语音说'];

  await page.goto(`${base}/`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  const welcome = await expectText(page, guest, 60000);

  await page.goto(`${base}/#/today`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  const todayText = await expectText(page, today, 40000);

  await page.goto(`${base}/#/chat`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  const chatText = await expectText(page, chat, 40000);

  const report = {
    edition,
    welcome_body_len: welcome.body.length,
    welcome_has: guest,
    today_body_len: todayText.body.length,
    today_has: today,
    chat_body_len: chatText.body.length,
    chat_has: chat,
    readable_host: Boolean(welcome.host || todayText.host || chatText.host),
  };
  console.log(JSON.stringify(report, null, 2));
} finally {
  await browser.close();
}
