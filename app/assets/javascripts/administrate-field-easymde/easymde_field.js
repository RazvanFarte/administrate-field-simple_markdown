/*!
 * administrate-field-easymde
 *
 * Attaches EasyMDE to every Administrate Markdown textarea on the page.
 *
 * Editors are found by data attribute rather than by element id, so a field
 * rendered more than once on a page (nested forms, Administrate's
 * NestedHasMany) gets an editor each. Rows added to the DOM after load are
 * picked up by a MutationObserver.
 */
(function () {
  "use strict";

  var SELECTOR = "textarea[data-easymde-options]";
  var INITIALIZED = "easymdeInitialized";
  var LOG_PREFIX = "[administrate-field-easymde]";

  function parseOptions(element) {
    var raw = element.getAttribute("data-easymde-options");
    if (!raw) return {};

    try {
      return JSON.parse(raw) || {};
    } catch (error) {
      console.error(LOG_PREFIX + " could not parse data-easymde-options", error, element);
      return {};
    }
  }

  /*
   * Turns "EasyMDE.toggleHeading4" into the function it names.
   *
   * Dashboards can only put strings in a data attribute, so a toolbar action
   * arrives here as a string. Walking the path from `window` does the same job
   * as eval() without needing 'unsafe-eval' in the Content-Security-Policy,
   * which admin panels usually set.
   */
  function resolveAction(action) {
    if (typeof action !== "string") return action;

    // A toolbar button's action may legitimately be a link target.
    if (/^(https?:)?\/\//.test(action) || action.charAt(0) === "#") return action;

    var resolved = action.split(".").reduce(function (context, key) {
      return context == null ? context : context[key];
    }, window);

    if (typeof resolved !== "function") {
      console.warn(LOG_PREFIX + ' toolbar action "' + action + '" is not a function');
      return undefined;
    }

    return resolved;
  }

  function normalizeToolbar(toolbar) {
    if (!Array.isArray(toolbar)) return toolbar;

    return toolbar.map(function (item) {
      if (!item || typeof item !== "object") return item; // "bold", "|"

      var button = Object.assign({}, item);
      if (button.action != null) button.action = resolveAction(button.action);
      if (Array.isArray(button.children)) button.children = normalizeToolbar(button.children);

      return button;
    });
  }

  /*
   * EasyMDE renders its preview pane with marked, which emits raw HTML - marked
   * dropped its own sanitizer in v4. Redcarpet's filter_html protects the pages
   * Rails renders, but not this one, so stored `<img src=x onerror=...>` would
   * run in an editor's browser the moment they click Preview. DOMPurify is
   * bundled to close that, and can be replaced or switched off per field.
   */
  function applySanitizer(options) {
    var rendering = Object.assign({}, options.renderingConfig);
    var configured = rendering.sanitizerFunction;

    if (configured === false || configured === null) {
      delete rendering.sanitizerFunction;
    } else if (typeof configured === "string") {
      rendering.sanitizerFunction = resolveAction(configured);
    } else if (typeof configured !== "function") {
      if (typeof window.DOMPurify === "undefined") {
        console.warn(LOG_PREFIX + " DOMPurify is missing; the preview pane is unsanitized");
      } else {
        rendering.sanitizerFunction = function (html) {
          return window.DOMPurify.sanitize(html);
        };
      }
    }

    options.renderingConfig = rendering;
    return options;
  }

  function initialize(element) {
    if (element.dataset[INITIALIZED] === "true") return;

    if (typeof window.EasyMDE !== "function") {
      console.error(LOG_PREFIX + " EasyMDE is not loaded");
      return;
    }

    var options = applySanitizer(parseOptions(element));
    if (options.toolbar) options.toolbar = normalizeToolbar(options.toolbar);
    options.element = element;

    element.dataset[INITIALIZED] = "true";

    try {
      element.easyMDE = new window.EasyMDE(options);
    } catch (error) {
      delete element.dataset[INITIALIZED];
      console.error(LOG_PREFIX + " failed to initialize an editor", error, element);
    }
  }

  function initializeAll(root) {
    var scope = root && root.querySelectorAll ? root : document;

    if (scope.matches && scope.matches(SELECTOR)) initialize(scope);
    Array.prototype.forEach.call(scope.querySelectorAll(SELECTOR), initialize);
  }

  /*
   * Turbo caches a snapshot of the page before navigating away. Without this,
   * the snapshot contains CodeMirror's rendered markup, and going back leaves
   * a dead editor on screen with a live one built on top of it.
   */
  function teardownAll() {
    Array.prototype.forEach.call(document.querySelectorAll(SELECTOR), function (element) {
      if (!element.easyMDE) return;

      element.easyMDE.toTextArea();
      element.easyMDE = null;
      delete element.dataset[INITIALIZED];
    });
  }

  function observeAddedFields() {
    if (!window.MutationObserver || !document.body) return;

    new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        Array.prototype.forEach.call(mutation.addedNodes, function (node) {
          if (node.nodeType === Node.ELEMENT_NODE) initializeAll(node);
        });
      });
    }).observe(document.body, { childList: true, subtree: true });
  }

  function start() {
    initializeAll(document);
    observeAddedFields();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }

  document.addEventListener("turbo:load", function () {
    initializeAll(document);
  });
  document.addEventListener("turbo:frame-load", function (event) {
    initializeAll(event.target);
  });
  document.addEventListener("turbo:before-cache", teardownAll);

  window.AdministrateFieldEasyMDE = {
    initializeAll: initializeAll,
    teardownAll: teardownAll
  };
})();
