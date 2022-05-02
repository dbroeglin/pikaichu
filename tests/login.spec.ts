import { test, expect, Page } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  await page.goto('http://localhost:3000');
});

test.describe('Login page', () => {
  test('should have login form', async ({ page }) => {

    await expect(page.locator('title')).toHaveText('PiKaichu');
    await expect(page.locator('#user_email')).toBeFocused();
    await expect(page.locator('#user_password')).toBeEmpty();
    await expect(page.locator('button[type=submit]')).toHaveText('Connexion');

  });
});