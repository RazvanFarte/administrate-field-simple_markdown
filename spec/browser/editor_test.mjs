/*
 * Browser suite for administrate-field-easymde.
 *
 * Run with `rake browser:test`, which boots the dummy Administrate app and
 * executes this file inside the official Playwright container.
 */
import test from "node:test";
import assert from "node:assert/strict";
import {
  BASE_URL,
  withPage,
  readCspViolations,
  thirdPartyRequests,
  editorCount
} from "./support/harness.mjs";

const EDITOR_FIELDS = Number(process.env.EDITOR_FIELDS || 3);
const NEW_ARTICLE = `${BASE_URL}/admin/articles/new`;

test("upgrades every Markdown textarea on the form", async () => {
  await withPage(async (page, { consoleErrors }) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    assert.equal(await editorCount(page), EDITOR_FIELDS);
    assert.deepEqual(consoleErrors, []);
    assert.deepEqual(await readCspViolations(page), []);
  });
});

test("loads nothing from a third-party origin", async () => {
  await withPage(async (page, { requests }) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");
    await page.waitForTimeout(500);

    assert.deepEqual(thirdPartyRequests(requests), []);
  });
});

test("draws every toolbar icon from the bundled set", async () => {
  await withPage(async (page) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    const missing = await page.evaluate(() => {
      const buttons = document.querySelectorAll(
        '.editor-toolbar button[class^="administrate-easymde-"]'
      );

      return Array.from(buttons)
        .filter((button) => {
          if (button.innerText.trim()) return false; // H4/H5/H6 use text, not an icon
          const icon = button.querySelector("i");
          if (!icon) return true;
          const mask = getComputedStyle(icon).maskImage || getComputedStyle(icon).webkitMaskImage;
          return !mask || mask === "none";
        })
        .map((button) => button.className);
    });

    assert.deepEqual(missing, []);
  });
});

test("runs a string toolbar action without eval", async () => {
  await withPage(async (page, { consoleErrors }) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    await page.evaluate(() => {
      document.querySelector("textarea[data-easymde-options]").easyMDE.value("Heading text");
    });
    await page.locator("button.administrate-easymde-heading-4").first().click();

    const value = await page.evaluate(
      () => document.querySelector("textarea[data-easymde-options]").easyMDE.value()
    );

    assert.match(value, /^#### /);
    assert.deepEqual(consoleErrors, []);
    assert.deepEqual(await readCspViolations(page), []);
  });
});

test("sanitizes hostile Markdown in the preview pane", async () => {
  await withPage(async (page) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    await page.evaluate(() => {
      window.__xss = false;
      document
        .querySelector("textarea[data-easymde-options]")
        .easyMDE.value(
          '<img src=x onerror="window.__xss = true"><script>window.__xss = true<\/script>' +
            '<a href="javascript:void(0)">link</a>'
        );
    });
    await page.locator("button.administrate-easymde-preview").first().click();
    await page.waitForTimeout(300);

    const result = await page.evaluate(() => {
      const preview = document.querySelector(".editor-preview");
      return {
        executed: window.__xss,
        html: preview ? preview.innerHTML : "",
        handlers: preview ? preview.querySelectorAll("[onerror], [onload], script").length : -1
      };
    });

    assert.equal(result.executed, false, "an event handler ran in the preview pane");
    assert.equal(result.handlers, 0, `preview kept scripting markup: ${result.html}`);
  });
});

test("escapes hostile Markdown on the index page", async () => {
  await withPage(async (page) => {
    await page.goto(`${BASE_URL}/admin/articles`);
    await page.waitForSelector("table");

    const executed = await page.evaluate(() => window.__xssFromShowPage === true);
    const scripts = await page.locator("table script").count();

    assert.equal(executed, false);
    assert.equal(scripts, 0);
  });
});

test("does not stack editors when Turbo restores a cached page", async () => {
  await withPage(async (page) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    await page.goto(`${BASE_URL}/admin/articles`);
    await page.waitForSelector("table");
    await page.goBack();
    await page.waitForSelector(".EasyMDEContainer");
    await page.waitForTimeout(300);

    assert.equal(await editorCount(page), EDITOR_FIELDS);
  });
});

test("initializes a field added to the DOM after load", async () => {
  await withPage(async (page) => {
    await page.goto(NEW_ARTICLE);
    await page.waitForSelector(".EasyMDEContainer");

    await page.evaluate(() => {
      const textarea = document.createElement("textarea");
      textarea.setAttribute("data-easymde-options", "{}");
      textarea.name = "article[body_added]";
      document.querySelector("form").appendChild(textarea);
    });
    await page.waitForTimeout(500);

    assert.equal(await editorCount(page), EDITOR_FIELDS + 1);
  });
});
