# administrate-field-easymde

[![Build status](https://github.com/RazvanFarte/administrate-field-simple_markdown/actions/workflows/build.yml/badge.svg)](https://github.com/RazvanFarte/administrate-field-simple_markdown/actions/workflows/build.yml)

A Markdown editor field for [Administrate], powered by [EasyMDE] and rendered
server-side with [Redcarpet]. This is a maintained fork of
`administrate-field-simple_markdown` by [Zooppa], updated for Administrate 1.0
and Rails 8: no jQuery, no `eval`, and no third-party CDN requests. See
[SECURITY.md](SECURITY.md) for what that buys you and [PERFORMANCE.md](PERFORMANCE.md)
for measured costs.

![Demo](https://raw.githubusercontent.com/RazvanFarte/administrate-field-simple_markdown/main/demo.gif)

## Installation

Add it to your `Gemfile`:

```ruby
gem 'administrate-field-easymde'
```

Run:

```bash
$ bundle install
```

Nothing else to wire up: the bundled JavaScript and CSS ship as a Rails
engine, which registers itself with Administrate and adds itself to your
asset precompile list automatically, under Sprockets or Propshaft.

### Upgrading from `administrate-field-simple_markdown`

Only the gem name changed. `Field::SimpleMarkdown` in your dashboards keeps
working unmodified, and every option below behaves the same way it always
did. Two things are worth knowing before you upgrade:

- The field no longer fetches a Font Awesome stylesheet or a spell-check
  dictionary from a CDN at request time - both are bundled now, so admin
  pages work offline and under a strict Content-Security-Policy. `spell_checker`
  now defaults to `false`; the browser's own spell-checker still works on the
  textarea.
- Custom toolbar actions are no longer run through `eval()`. See
  [Custom toolbar actions](#custom-toolbar-actions) below if a dashboard
  configures its own toolbar.

## Usage

Add to your `FooDashboard`:

```ruby
ATTRIBUTE_TYPES = {
  bar: Field::SimpleMarkdown.with_options({
    safe_links_only: true,
    filter_html: true,
    with_toc_data: true,
    hard_wrap: true,
    link_attributes: { rel: 'nofollow' },
    autolink: true,
    tables: true,
    no_intra_emphasis: true,
    strikethrough: true,
    highlight: true,
    space_after_headers: true,
    easymde_options: {
      placeholder: 'Type here...',
      spell_checker: false,
      hide_icons: %w[guide heading]
    }
  })
}.freeze
```

`Field::EasyMDE` is the same field under a name that matches the gem, for
dashboards that would rather not write `SimpleMarkdown`:

```ruby
ATTRIBUTE_TYPES = {
  bar: Field::EasyMDE.with_options(...)
}.freeze
```

### Rendering options

The options above (`safe_links_only`, `filter_html`, `with_toc_data`,
`hard_wrap`, `link_attributes`, `autolink`, `tables`, `no_intra_emphasis`,
`strikethrough`, `highlight`, `space_after_headers`) are passed straight
through to Redcarpet and default to the values shown. Three more are specific
to this field:

- `truncate_length` - characters shown on the index page before truncation.
  Defaults to `30`, matching Rails' own `truncate`.
- `preview_source_limit` - how much of the raw Markdown source the index
  page's preview is allowed to read before truncating. Defaults to
  `[truncate_length * 4, 256].max`, generous because stripping Markdown
  shrinks text. Pass `nil` to render the whole document before truncating.
- `sanitize` - if a dashboard sets `filter_html: false` to let some HTML
  through, the output is run through Rails' allow-list sanitizer by default,
  configurable with `sanitize_tags:` and `sanitize_attributes:`. Pass
  `sanitize: false` to restore the old, unsafe behaviour and let raw HTML
  through unfiltered. See [SECURITY.md](SECURITY.md#1-the-show-page-to_html-server-side)
  for what each combination actually renders.

### EasyMDE options

You can pass EasyMDE a configuration object via the `easymde_options` option.
Check the [full list of available options](https://github.com/Ionaru/easy-markdown-editor#options-list).
Keys are written snake_case, same as everywhere else in the options hash, and
camelized before being handed to EasyMDE.

To use a sanitizer other than the bundled [DOMPurify](https://github.com/cure53/DOMPurify)
for the editor's live preview pane, pass the dotted name of a global function:

```ruby
easymde_options: { rendering_config: { sanitizer_function: 'MyApp.sanitize' } }
```

Passing `sanitizer_function: false` disables sanitizing entirely. See
[SECURITY.md](SECURITY.md#3-the-editors-preview-pane-client-side) for why this
matters even though Redcarpet already filters HTML server-side.

### Custom toolbar actions

Toolbar actions are resolved by walking a named path from `window`, the same
way `rendering_config.sanitizer_function` is - not by `eval()` - so they work
under a `script-src 'self'` Content-Security-Policy. Reference a global
function your own JavaScript defines:

```ruby
Field::EasyMDE.with_options({
  easymde_options: {
    toolbar: [
      'bold', '|', 'heading-3',
      {
        name: 'heading-4',
        action: 'MyApp.toggleHeading4',
        text: 'H4',
        title: 'H4'
      }
    ],
    line_numbers: true,
    autofocus: true,
    placeholder: 'Type here...',
    spell_checker: false,
    side_by_side_fullscreen: false
  }
})
```

`toggleHeading4` above is not a built-in EasyMDE action - EasyMDE only ships
H1-H3 - so `MyApp.toggleHeading4` has to be a function your application
defines on `window`. H5 and H6 work the same way.

## About

`administrate-field-easymde` is maintained by [Razvan Dan Farte], as a fork of
`administrate-field-simple_markdown` by [Zooppa].

See also the list of [contributors](https://github.com/zooppa/administrate-field-simple_markdown/contributors)
who participated in the original project.

[administrate]: https://github.com/thoughtbot/administrate
[easymde]: https://github.com/Ionaru/easy-markdown-editor
[redcarpet]: https://github.com/vmg/redcarpet
[zooppa]: https://www.zooppa.com/
[razvan dan farte]: https://github.com/RazvanFarte
