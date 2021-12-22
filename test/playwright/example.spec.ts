import { test, expect } from '@playwright/test';

test('check home page', async ({ page }) => {
  await page.goto('https://pikaichu.herokuapp.com/');

  var title = page.locator('p.title >> nth=0');
  await expect(title).toHaveText('Taikais');

  title = page.locator('p.title >> nth=1');
  await expect(title).toHaveText('Dojos');

});


test('new taikai', async ({ page }) => {
  await page.goto('https://pikaichu.herokuapp.com/');


  await page.click('text="Manage Taikais"');
  var title = page.locator('h1.title');

  await expect(title).toHaveText('Taikais');

});
