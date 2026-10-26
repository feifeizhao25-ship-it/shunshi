import { defineConfig } from '@playwright/test';

const artifacts = process.env.UI_TEST_ARTIFACT_DIR || '/opt/cursor/artifacts/ui-test';

export default defineConfig({
  testDir: '.',
  timeout: 240_000,
  expect: { timeout: 20_000 },
  outputDir: `${artifacts}/playwright-output`,
  reporter: [['list']],
  use: {
    browserName: 'chromium',
    channel: 'chrome',
    baseURL: process.env.SHUNSHI_WEB_URL || 'http://127.0.0.1:8090',
    actionTimeout: 20_000,
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    screenshot: 'off',
    video: 'off',
    trace: 'off',
    launchOptions: {
      args: [
        '--no-sandbox',
        '--disable-dev-shm-usage',
        '--use-gl=angle',
        '--use-angle=swiftshader',
        '--enable-webgl',
        '--ignore-gpu-blocklist',
        '--enable-unsafe-swiftshader',
      ],
    },
  },
});
