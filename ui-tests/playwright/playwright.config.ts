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
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    screenshot: 'off',
    video: 'off',
    trace: 'off',
  },
});
