/*
 * Shared setup for the browser suite and the browser benchmark.
 *
 * Both run inside the official Playwright container (see `rake browser:test`),
 * against the dummy Administrate app served on the host's loopback interface.
 */
import { chromium } from "playwright-core";

export const BASE_URL = process.env.BASE_URL || "http://127.0.0.1:3123";

export async function withPage(callback, options = {}) {
  const browser = await chromium.launch();
  const context = await browser.newContext(options.contextOptions);
  const page = await context.newPage();

  const consoleErrors = [];
  const requests = [];

  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => consoleErrors.push(String(error)));
  page.on("request", (request) => requests.push(request.url()));

  // Recorded in the page so a violation is caught even when the browser blocks
  // the offending resource silently.
  await context.addInitScript(() => {
    window.__cspViolations = [];
    document.addEventListener("securitypolicyviolation", (event) => {
      window.__cspViolations.push(event.violatedDirective + " " + event.blockedURI);
    });
  });

  try {
    return await callback(page, { consoleErrors, requests });
  } finally {
    await browser.close();
  }
}

export async function readCspViolations(page) {
  return page.evaluate(() => window.__cspViolations || []);
}

// blob: and data: URLs are created by the page itself, so they are not
// third-party fetches; Administrate 1.0 loads a polyfill stylesheet from one.
const LOCAL_SCHEMES = ["data:", "blob:", "about:"];

export function thirdPartyRequests(requests, baseUrl = BASE_URL) {
  const origin = new URL(baseUrl).origin;

  return requests.filter(
    (url) => !url.startsWith(origin) && !LOCAL_SCHEMES.some((scheme) => url.startsWith(scheme))
  );
}

export function editorCount(page) {
  return page.locator(".EasyMDEContainer").count();
}
