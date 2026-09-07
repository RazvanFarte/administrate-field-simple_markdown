/*
 * Measures what an EasyMDE editor costs in the browser, and how that scales
 * with the number of Markdown fields on one Administrate form.
 *
 * Run with: bundle exec rake bench:browser
 */
import { chromium } from "playwright-core";

const BASE_URL = process.env.BASE_URL || "http://127.0.0.1:3123";
const EDITORS = Number(process.env.EDITOR_FIELDS || 3);
const REPEATS = Number(process.env.BENCH_REPEATS || 3);

// Injected before any page script runs, so the timestamp of the last editor to
// appear is recorded from inside the page rather than guessed by polling.
const RECORDER = () => {
  window.__editorReady = [];

  // Re-queries rather than inspecting the added node: EasyMDE builds its
  // container and sets the class on it in more than one step, so an added node
  // is not necessarily classed yet at the moment the mutation fires.
  const record = () => {
    const found = document.querySelectorAll(".EasyMDEContainer").length;
    while (window.__editorReady.length < found) {
      window.__editorReady.push(performance.now());
    }
  };

  // Observes `document`, not `document.documentElement`: an init script runs
  // before the document element exists.
  new MutationObserver(record).observe(document, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class"]
  });
};

async function measure(page, url) {
  // Loaded once and thrown away: the first navigation of a session also pays
  // for downloading the bundle, which is a one-off cost per browser, not a
  // per-editor one. Init scripts re-run on each navigation, so the recorder
  // starts empty again.
  await page.goto(url, { waitUntil: "load" });
  await page.goto(url, { waitUntil: "load" });
  await page.waitForFunction(
    (expected) => (window.__editorReady || []).length >= expected,
    EDITORS,
    { timeout: 30000 }
  );

  return page.evaluate(() => {
    const navigation = performance.getEntriesByType("navigation")[0];
    const ready = window.__editorReady;

    return {
      domContentLoaded: navigation.domContentLoadedEventEnd,
      load: navigation.loadEventEnd,
      lastEditorReady: Math.max(...ready),
      editors: ready.length,
      domNodes: document.getElementsByTagName("*").length,
      heapMb: performance.memory
        ? performance.memory.usedJSHeapSize / (1024 * 1024)
        : null
    };
  });
}

const browser = await chromium.launch();
const context = await browser.newContext();
await context.addInitScript(RECORDER);
const page = await context.newPage();

// Repeated and reduced to a median: a single navigation is noisy enough that
// the trend across editor counts would not be readable.
async function median(page, url) {
  const runs = [];
  for (let i = 0; i < REPEATS; i += 1) runs.push(await measure(page, url));

  const middle = (key) => runs.map((run) => run[key]).sort((a, b) => a - b)[Math.floor(REPEATS / 2)];

  return {
    domContentLoaded: middle("domContentLoaded"),
    lastEditorReady: middle("lastEditorReady"),
    domNodes: middle("domNodes"),
    heapMb: runs[runs.length - 1].heapMb
  };
}

const empty = await median(page, `${BASE_URL}/admin/articles/new`);
const filled = await median(page, `${BASE_URL}/bench/edit`);

// Per-editor figures are deliberately absent: dividing a page total by the
// editor count charges each editor a share of the fixed page cost. The
// marginal cost of one more editor is the slope across rows of this table.
const row = (label, m) =>
  `| ${label} | ${EDITORS} | ${m.domContentLoaded.toFixed(0)} ms | ` +
  `${m.lastEditorReady.toFixed(0)} ms | ${m.domNodes} | ` +
  `${m.heapMb === null ? "n/a" : m.heapMb.toFixed(1) + " MB"} |`;

console.log(row("empty", empty));
console.log(row("10k chars each", filled));

await browser.close();
