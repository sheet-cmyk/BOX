import { test, expect } from '@playwright/test';
test('public pages, five programs, mobile navigation and waiver draft', async ({page}) => {
  const errors:string[]=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('/programs');
  for(const name of ['Boxing Training','Fitness Training','Strength and Conditioning','Weight Loss Training','Self Defense Training']) await expect(page.getByRole('heading',{name,exact:true})).toBeVisible();
  await page.goto('/waiver');await expect(page.getByText('Draft for gym review.',{exact:false})).toBeVisible();await expect(page.getByRole('button',{name:'Record My Agreement'})).toHaveCount(0);
  await page.setViewportSize({width:390,height:844});await page.goto('/');
  await page.getByRole('button',{name:'Open menu'}).click();await page.getByRole('navigation',{name:'Main navigation'}).getByRole('link',{name:'Programs',exact:true}).click();await expect(page).toHaveURL(/\/programs/);
  expect(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth+1)).toBeTruthy();
  for(const route of ['/about','/schedule','/pricing','/contact','/privacy','/terms','/signin','/signup']) { const response=await page.goto(route);expect(response?.status()).toBe(200);await expect(page.locator('main h1').first()).toBeVisible(); }
  expect(errors).toEqual([]);
});
test('member profile, payment availability and admin access protection', async ({page})=>{
  await page.goto('/signin');await page.getByLabel('Email',{exact:true}).fill('member@example.test');await page.getByLabel('Password',{exact:true}).fill('UiTestPass123!');await page.getByRole('button',{name:'Sign In →',exact:true}).click();await expect(page).toHaveURL(/dashboard/);
  await page.goto('/settings');await page.getByLabel('Participant name (yourself or child)').fill('Updated Boxer');await page.getByRole('button',{name:'Save Changes'}).click();await expect(page.getByText('Profile saved.',{exact:true})).toBeVisible();
  await page.goto('/checkout?plan=ten');await expect(page.getByText('Card payments are not configured yet.',{exact:false})).toBeVisible();
  await page.goto('/payments');await expect(page.getByRole('heading',{name:'Payment history'})).toBeVisible();
  await page.goto('/admin');await expect(page.getByText('Administrator access is required.')).toBeVisible();
});
test('administrator navigation, email search, payment filters and waiver editor', async ({page})=>{
  await page.goto('/signin?next=/admin');await page.getByLabel('Email',{exact:true}).fill('admin@example.test');await page.getByLabel('Password',{exact:true}).fill('UiTestPass123!');await page.getByRole('button',{name:'Sign In →',exact:true}).click();await expect(page).toHaveURL(/\/admin$/);
  for(const route of ['/admin/schedule','/admin/bookings','/admin/plans','/admin/payments','/admin/notifications','/admin/settings','/admin/waiver']) {await page.goto(route);await expect(page.locator('main h1')).toBeVisible();await expect(page.locator('.notice.error')).toHaveCount(0);}
  await page.goto('/admin/members');await page.getByLabel('Search member name or email').fill('member@');await expect(page.getByRole('cell',{name:'member@example.test'})).toBeVisible();
  await page.goto('/admin/payments');await page.getByLabel('Status',{exact:true}).selectOption('completed');await page.getByLabel('Method',{exact:true}).selectOption('cash');await expect(page.getByText('No matching payments.')).toBeVisible();await expect(page.locator('.notice.error')).toHaveCount(0);
});
