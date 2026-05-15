import { test, expect } from '@playwright/test';

test.describe('Chat Interface', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for app to load
    await page.waitForSelector('#chat-input', { timeout: 10000 });
  });

  test('should display chat interface', async ({ page }) => {
    // Check main elements are visible
    await expect(page.locator('#chat-input')).toBeVisible();
    await expect(page.locator('#send-btn')).toBeVisible();
    await expect(page.locator('.chat-container')).toBeVisible();
  });

  test('should send a message', async ({ page }) => {
    const testMessage = 'Hello, this is a test message';
    
    // Type message
    await page.fill('#chat-input', testMessage);
    
    // Click send
    await page.click('#send-btn');
    
    // Check message appears in chat
    await expect(page.locator('.message.user').last()).toContainText(testMessage);
  });

  test('should show loading state while streaming', async ({ page }) => {
    // Send a message
    await page.fill('#chat-input', 'Test message');
    await page.click('#send-btn');
    
    // Check for loading indicator or streaming state
    await expect(page.locator('.typing-indicator, .message.assistant')).toBeVisible({ timeout: 5000 });
  });

  test('should clear input after sending', async ({ page }) => {
    await page.fill('#chat-input', 'Test message');
    await page.click('#send-btn');
    
    // Check input is cleared
    await expect(page.locator('#chat-input')).toHaveValue('');
  });

  test('should handle long messages', async ({ page }) => {
    const longMessage = 'A'.repeat(500);
    
    await page.fill('#chat-input', longMessage);
    await page.click('#send-btn');
    
    // Message should be sent and visible
    await expect(page.locator('.message.user').last()).toBeVisible();
  });

  test('should be responsive on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Elements should still be visible
    await expect(page.locator('#chat-input')).toBeVisible();
    await expect(page.locator('#send-btn')).toBeVisible();
  });
});
