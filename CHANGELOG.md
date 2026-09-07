# Changelog

## v1.0.0

[Full Changelog](https://github.com/RazvanFarte/administrate-field-simple_markdown/compare/v0.7.0...v1.0.0)

Renamed the gem to `administrate-field-easymde`. `Field::SimpleMarkdown` in
existing dashboards keeps working unmodified; `Field::EasyMDE` is now available
as a name that matches the gem.

- Add support for Administrate 1.0 and Rails 8. Drop the dependency on the
  `rails` meta-gem - depend on `actionview`, `activesupport` and `railties`
  directly instead - which is what made 0.7.0 uninstallable on Rails 7.1+
  through a `rack ~> 2` pin Rails 8 cannot satisfy.
- Upgrade EasyMDE 2.18.0 -> 2.21.0 and its bundled CodeMirror 5.65.9 -> 5.65.15.
  Raise the Redcarpet floor to `~> 3.6`, fixing CVE-2020-26298 (unescaped
  quotes in link/image attributes).
- Stop fetching a Font Awesome stylesheet and a spell-check dictionary from
  third-party CDNs at request time. Both are bundled in the gem now, so admin
  pages work offline and under a Content-Security-Policy with no third-party
  origins allowed. `spell_checker` now defaults to `false`.
- Remove the inline `<script>` per field and the `eval()` call on toolbar
  action strings. Toolbar actions and the preview pane's sanitizer function
  are now resolved by walking a named path from `window`, so the field needs
  neither `unsafe-inline` nor `unsafe-eval` in `script-src`.
- Bundle [DOMPurify](https://github.com/cure53/DOMPurify) and install it as
  EasyMDE's preview-pane sanitizer by default. `marked`, which EasyMDE uses to
  render that preview, dropped its own sanitizer in v4 and Redcarpet's
  server-side `filter_html` never saw that path - stored HTML could run in an
  editor's browser the moment Preview was clicked. See
  [SECURITY.md](SECURITY.md).
- Add a `sanitize` option: dashboards that set `filter_html: false` to allow
  some HTML through now get that HTML run through Rails' allow-list sanitizer
  by default, configurable with `sanitize_tags:`/`sanitize_attributes:`, with
  `sanitize: false` available to opt back into the old, unfiltered behaviour.
- Add `#preview`, a plain-text index-page summary that strips a slice of the
  raw Markdown source instead of rendering the whole document and discarding
  it, and a `preview_source_limit` option to control how much of the source
  it reads. See [PERFORMANCE.md](PERFORMANCE.md) for the measured effect on
  index pages with a Markdown column.
- Add a 52-example XSS payload corpus and a browser test suite (Playwright,
  run once plainly and once under a strict CSP) covering the show page, the
  index preview and the editor's own preview pane.
- Add `PERFORMANCE.md` and `SECURITY.md`, and a `bench/` rake task
  (`rake bench:redcarpet`, `rake bench:postgres`, `rake bench:browser`)
  backing the numbers in the former.

## [v0.7.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.7.0) (2020-01-06)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.6.0...v0.7.0)

- Add support for Rails 7 (thanks @neumayr)

## [v0.6.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.6.0) (2020-07-01)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.5.0...v0.6.0)

- Support nonce for Content Security Policy (thanks @parterburn)

## [v0.5.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.5.0) (2020-05-28)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.4.0...v0.5.0)

- Add support for full EasyMDE configuration (thanks @hernanvicente)

## [v0.4.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.4.0) (2020-05-28)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.3.0...v0.4.0)

- Revert initialization logic to HTML ID. This won’t be compatible with other
  Administrate plugin (e.g. Administrate::Field::NestedHasMany)
- Switch to EasyMDE (thanks @casaper)

## [v0.3.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.3.0) (2020-03-16)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.2.1...v0.3.0)

- Support namespaced models and injected fields (thanks @sedubois)
- Add support for Redcarpet options (thanks @casaper)

## [v0.2.1](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.2.1) (2019-01-15)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.2.0...v0.2.1)

- Require Rack greater than 2.0.8

## [v0.2.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.2.0) (2018-08-27)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.1.2...v0.2.0)

- Update the requirements on Rails to permit the latest version

## [v0.1.2](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.1.2) (2018-05-24)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.1.1...v0.1.2)

- Use snakecase when generating ID (thanks @golmansax)

## [v0.1.1](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.1.1) (2018-03-09)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.1.0...v0.1.1)

- Restore list styles for Markdown elements (thanks @pedantic-git)

## [v0.1.0](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.1.0) (2018-01-23)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.0.4...v0.1.0)

- Require Redcarpet
- Add RSpec and tests
- Handle null data
- Update documentation

## [v0.0.4](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.0.4) (2017-04-03)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.0.3...v0.0.4)

- Bump up Administrate dependency

## [v0.0.3](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.0.3) (2017-03-20)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.0.2...v0.0.3)

- Bump up Administrate dependency

## [v0.0.2](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.0.2) (2016-11-22)

[Full Changelog](https://github.com/zooppa/administrate-field-simple_markdown/compare/v0.0.1...v0.0.2)

- Bump up Administrate dependency

## [v0.0.1](https://github.com/zooppa/administrate-field-simple_markdown/tree/v0.0.1) (2016-11-16)

First release
