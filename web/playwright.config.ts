import { defineConfig, devices } from '@playwright/test';
export default defineConfig({testDir:'./tests',timeout:90000,expect:{timeout:20000},workers:1,retries:0,reporter:'list',use:{baseURL:process.env.UI_BASE_URL || 'http://127.0.0.1:3010',trace:'retain-on-failure',screenshot:'only-on-failure'},projects:[{name:'chromium',use:{...devices['Desktop Chrome']}}]});
