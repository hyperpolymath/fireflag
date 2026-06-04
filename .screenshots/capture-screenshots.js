// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#!/usr/bin/env -S deno run --allow-read --allow-write --allow-net --allow-run --allow-env
// Automated screenshot capture for FireFlag extension

import puppeteer from "https://deno.land/x/puppeteer@16.2.0/mod.ts";
import { ensureDir } from "https://deno.land/std@0.224.0/fs/mod.ts";

const SCREENSHOTS_DIR = new URL("./", import.meta.url).pathname;
const EXTENSION_PATH = new URL("../extension/", import.meta.url).pathname;

console.log("FireFlag Screenshot Capture");
console.log("===========================");
console.log(`Extension path: ${EXTENSION_PATH}`);
console.log(`Output directory: ${SCREENSHOTS_DIR}`);
console.log("");

// Ensure output directory exists
await ensureDir(SCREENSHOTS_DIR);

// Launch Firefox with extension loaded
console.log("Launching Firefox with FireFlag extension...");
const browser = await puppeteer.launch({
  product: "firefox",
  headless: false, // Need to see the UI for screenshots
  args: [
    `--load-extension=${EXTENSION_PATH}`,
    "--window-size=1280,800",
  ],
  defaultViewport: {
    width: 1280,
    height: 800,
  },
});

const page = await browser.newPage();

// Helper function to capture screenshot
async function captureScreenshot(name, selector, options = {}) {
  console.log(`Capturing: ${name}...`);

  const outputPath = `${SCREENSHOTS_DIR}${name}.png`;

  if (selector) {
    const element = await page.$(selector);
    if (element) {
      await element.screenshot({
        path: outputPath,
        ...options,
      });
    } else {
      console.warn(`  ⚠ Element not found: ${selector}`);
      return;
    }
  } else {
    await page.screenshot({
      path: outputPath,
      fullPage: options.fullPage || false,
      ...options,
    });
  }

  console.log(`  ✓ Saved: ${name}.png`);
}

try {
  // 1. POPUP SCREENSHOT
  console.log("\n1. Capturing Popup UI...");
  console.log("   Please manually open the extension popup");
  console.log("   Press Enter when ready...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("01-popup-overview", null, {
    clip: { x: 0, y: 0, width: 400, height: 600 }
  });

  // 2. SIDEBAR SCREENSHOT
  console.log("\n2. Capturing Sidebar...");
  console.log("   Please open the sidebar (View > Sidebar > FireFlag)");
  console.log("   Press Enter when ready...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("02-sidebar-flags-tab", null, {
    clip: { x: 0, y: 0, width: 350, height: 700 }
  });

  console.log("   Switch to Tracking tab and press Enter...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("03-sidebar-tracking-tab", null, {
    clip: { x: 0, y: 0, width: 350, height: 700 }
  });

  console.log("   Switch to Analytics tab and press Enter...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("04-sidebar-analytics-tab", null, {
    clip: { x: 0, y: 0, width: 350, height: 700 }
  });

  // 3. OPTIONS PAGE SCREENSHOT
  console.log("\n3. Capturing Options Page...");
  await page.goto("about:addons");
  await page.waitForTimeout(1000);

  console.log("   Navigate to FireFlag > Preferences");
  console.log("   Press Enter when on options page...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("05-options-general", null, { fullPage: true });

  // 4. DEVTOOLS SCREENSHOT
  console.log("\n4. Capturing DevTools Panel...");
  console.log("   Open DevTools (F12)");
  console.log("   Navigate to FireFlag tab");
  console.log("   Press Enter when ready...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("06-devtools-active-flags", null, {
    clip: { x: 0, y: 400, width: 1280, height: 400 }
  });

  console.log("   Switch to Performance tab in DevTools and press Enter...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("07-devtools-performance", null, {
    clip: { x: 0, y: 400, width: 1280, height: 400 }
  });

  // 5. PERMISSION PROMPT SCREENSHOT
  console.log("\n5. Capturing Permission Prompt...");
  console.log("   Trigger a permission request (toggle a flag requiring permissions)");
  console.log("   Press Enter when prompt is visible...");
  await new Promise(resolve => {
    const listener = Deno.stdin.read(new Uint8Array(1));
    listener.then(() => resolve());
  });

  await captureScreenshot("08-permission-request", null, {
    clip: { x: 400, y: 200, width: 480, height: 300 }
  });

  console.log("\n✓ All screenshots captured!");
  console.log(`\nScreenshots saved to: ${SCREENSHOTS_DIR}`);

} catch (error) {
  console.error("Error capturing screenshots:", error);
} finally {
  await browser.close();
}

console.log("\nScreenshot capture complete!");
console.log("Next steps:");
console.log("  1. Review screenshots in .screenshots/");
console.log("  2. Optimize images: just optimize-screenshots");
console.log("  3. Add to store listing");
