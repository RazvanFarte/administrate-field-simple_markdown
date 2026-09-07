# Security

This field takes text an author typed, turns it into HTML, and marks that HTML
`html_safe` so Rails will not escape it. That is the whole risk surface, and it
is the reason this document exists.

Everything claimed below is asserted by a test. The payload corpus lives in
`spec/lib/administrate/field/simple_markdown_security_spec.rb` (52 examples) and
the browser assertions in `spec/browser/editor_test.mjs`, which runs twice: once
normally and once with the admin served under a strict Content-Security-Policy.

## Reporting a vulnerability

Open a GitHub issue, or email the address in the gemspec. There is no embargo
process; this is a single-maintainer gem.

## OWASP Top 10 (2021) checklist

| # | Category | Status | Notes |
|---|---|---|---|
| A01 | Broken Access Control | **Not this gem** | Administrate renders the field only inside a dashboard you have already authorized. The field does no authorization of its own and must not be the place you add it. |
| A02 | Cryptographic Failures | **Not applicable** | No secrets, no crypto, no storage of its own. |
| A03 | Injection (XSS) | **Addressed** | See [Cross-site scripting](#cross-site-scripting) below. Both render paths and the editor preview are covered. |
| A04 | Insecure Design | **Addressed** | Turning off Redcarpet's `filter_html` downgrades to allow-listed HTML rather than to raw HTML. Getting raw HTML now takes a second, explicit `sanitize: false`. |
| A05 | Security Misconfiguration | **Addressed** | Ships safe defaults: HTML filtered, links scheme-checked, spell-check dictionary and icon font not fetched from third parties. Runs under `script-src 'self'` with no violations. |
| A06 | Vulnerable and Outdated Components | **Addressed** | EasyMDE 2.18.0 (2022) → 2.21.0, CodeMirror 5.65.9 → 5.65.15, Redcarpet floor raised to 3.6. See [Dependencies](#dependencies). |
| A07 | Identification and Authentication Failures | **Not applicable** | No identity handling. |
| A08 | Software and Data Integrity Failures | **Addressed** | 0.7.0 pulled a stylesheet and a spell-check dictionary from two CDNs at runtime, with no Subresource Integrity. Both are now bundled in the gem. |
| A09 | Logging and Monitoring Failures | **Not applicable** | The field logs nothing. |
| A10 | Server-Side Request Forgery | **Not applicable** | Nothing in the render path fetches a URL. Markdown image URLs are rendered as `<img src>` for the browser to fetch, not fetched server-side. |

## Cross-site scripting

There are three places a document is turned into markup, and each needed its own
answer.

### 1. The show page (`#to_html`, server-side)

Redcarpet renders with `filter_html: true` and `safe_links_only: true` by
default. Every payload in the corpus - script elements, event-handler
attributes, `javascript:`, `vbscript:` and `data:` URLs, mixed case and
entity-encoded schemes, quote-escapes in image alt text, link titles and heading
anchors - produces output with no script element, no `on*` attribute and no
scripting URL scheme.

If a dashboard sets `filter_html: false` because it wants some HTML through, the
output is now run through Rails' allow-list sanitizer first, so:

```ruby
Field::SimpleMarkdown.with_options(filter_html: false)
# "<script>alert(1)</script>"        -> "alert(1)"
# "<img src=x onerror=alert(1)>"     -> "<img src=\"x\">"
# "<a href=\"javascript:...\">x</a>" -> "<a>x</a>"
# "<em>kept</em>"                    -> "<em>kept</em>"
```

`sanitize: false` restores the old, unsafe behaviour. It exists for the case
where content is authored by trusted staff and you need something the allow-list
strips; the corpus asserts that it really does let a `<script>` element through,
so nobody can adopt it by accident.

### 2. The index page (`#preview` and `#to_s`, server-side)

These return plain `String`s, not `html_safe` ones, so ERB escapes them. They
are *not* HTML-free: Redcarpet's `StripDown` renderer passes literal HTML source
through, so a document containing `<script>` comes back containing the
characters `<script>`. That is displayed as text, which is correct - but do not
call `.html_safe` on the result, and do not assume it is markup-free when
putting it somewhere other than an ERB template.

### 3. The editor's preview pane (client-side)

This is the one that is easy to miss. EasyMDE renders its preview with
[marked](https://marked.js.org/), which dropped its built-in sanitizer in v4 and
emits raw HTML. Redcarpet never sees that path. So stored content like
`<img src=x onerror="...">` would run in an editor's browser the moment they
opened the record and clicked Preview - server-side filtering does nothing about
it.

The gem bundles [DOMPurify](https://github.com/cure53/DOMPurify) and installs it
as EasyMDE's `renderingConfig.sanitizerFunction` by default. The browser suite
sets a hostile document into a live editor, clicks Preview, and asserts that no
handler fired and that no `script`, `onerror` or `onload` survived in the
preview DOM.

To use a different sanitizer, pass the dotted name of a global function:

```ruby
easymde_options: { rendering_config: { sanitizer_function: 'MyApp.sanitize' } }
```

Passing `sanitizer_function: false` disables sanitizing entirely, which puts you
back where EasyMDE's defaults leave you.

## Content-Security-Policy

The field needs no `unsafe-inline` and no `unsafe-eval` for **scripts**, and
loads nothing from a third-party origin. The browser suite runs the whole
admin under:

```
default-src 'self'; script-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline' blob:
```

and asserts zero `securitypolicyviolation` events.

Two caveats about `style-src`, both about code this gem does not own:

- **CodeMirror 5 writes inline `style` attributes** while laying out the editor,
  so `style-src` needs `'unsafe-inline'`. This is inherent to EasyMDE's editor
  core and cannot be fixed from here.
- **Administrate 1.0 loads its CSS anchor positioning polyfill from a `blob:`
  URL**, so `style-src` needs `blob:`. That is Administrate's own bundle, not
  this gem's; `grep -c createObjectURL` finds two occurrences in Administrate's
  build and none in this one.

### What 0.7.0 required and this version does not

The old form partial emitted an inline `<script>` per field and called `eval()`
on toolbar action strings taken from the dashboard configuration. Under a policy
worth having, that needed both `'unsafe-inline'` and `'unsafe-eval'` - which is
to say the CSP nonce support added in 0.6.0 bought less than it looked like.
Toolbar actions are now resolved by walking the named path from `window`, and
the browser suite clicks a custom H4 button under `script-src 'self'` to prove
it.

## Dependencies

| Component | 0.7.0 | Now | Why it matters |
|---|---|---|---|
| EasyMDE | 2.18.0 (Sep 2022) | 2.21.0 (May 2026) | Three years of fixes, including an excessive-memory bug in `previewImagesInEditor`. |
| CodeMirror (bundled in EasyMDE) | 5.65.9 | 5.65.15 | Editor core. |
| marked (bundled in EasyMDE) | v4 | v4 | v4.0.10+ carries the fixes for the 2022 ReDoS advisories. Its lack of a sanitizer is handled by DOMPurify, above. |
| Redcarpet | `~> 3.3` | `~> 3.6` | `~> 3.3` is satisfied by versions older than 3.5.1, which fixed CVE-2020-26298: quotes were processed without HTML escaping, giving an XSS that worked even with `escape_html` enabled. |
| Font Awesome | fetched from `maxcdn.bootstrapcdn.com` at runtime | bundled Bootstrap Icons | No third-party request, no SRI gap, works offline and under CSP. |
| Spell-check dictionary | fetched from `cdn.jsdelivr.net` at runtime | not fetched | `spellChecker` now defaults to `false`; the browser's own spell-checker still works on the textarea. |

## Things this gem deliberately does not do

- **It does not authenticate or authorize anything.** Administrate does that.
- **It does not limit document size.** See [PERFORMANCE.md](PERFORMANCE.md) for
  measured costs and a recommended ceiling; enforce it with a model validation
  if you need one, because a 1 MB document is a slow page, not a rejected one.
- **It does not sanitize on write.** Documents are stored as typed and cleaned
  on render, so turning sanitizing on or off changes what existing records look
  like immediately, without a backfill.
