# Administrate::Field::SimpleMarkdown

[![Build status](https://github.com/zooppa/administrate-field-simple_markdown/actions/workflows/build.yml/badge.svg)](https://github.com/zooppa/administrate-field-simple_markdown/actions/workflows/build.yml)
[![Code Climate](https://codeclimate.com/github/zooppa/administrate-field-simple_markdown/badges/gpa.svg)](https://codeclimate.com/github/zooppa/administrate-field-simple_markdown)

A plugin to edit Markdown text in [Administrate] using [EasyMDE].

![Demo](https://raw.githubusercontent.com/zooppa/administrate-field-simple_markdown/master/demo.gif)

## Usage

Add it to your `Gemfile`:

```ruby
gem 'administrate-field-simple_markdown', '~> 0.7.0'
```

Run:

```bash
$ bundle install
```

Add to your `FooDashboard`:

```ruby
ATTRIBUTE_TYPES = {
  bar: Field::SimpleMarkdown.with_options({
    safe_links_only: true,
    filter_html: true,
    with_toc_data: true,
    hard_wrap: true,
    link_attributes: { rel: 'follow' },
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

You can pass EasyMDE a configuration object via the `easymde_options` option.
Check the [full list of available options](https://github.com/Ionaru/easy-markdown-editor#options-list).

### Configure H4, H5 and H6 headings
```
Field::SimpleMarkdown.with_options({
      easymde_options: {
        toolbar: ['bold', '|', 'heading-3', 
        {
          name: 'heading-4',
          action: 'EasyMDE.toggleHeading4',
          text: 'H4',
          title: 'H4'
      }],
        lineNumbers: true,
        autofocus: true,
        placeholder: 'Type here...',
        spell_checker: false,
        sideBySideFullscreen: false,
        hide_icons: %w[]
      }
    }),
```

For H5 and H6, the specification is similar to the above.
Make sure to wrap the action with `' '`.

## About

Administrate::Field::SimpleMarkdown is maintained by [Zooppa].

See also the list of [contributors](https://github.com/zooppa/administrate-field-simple_markdown/contributors) who participated in this project.

[administrate]: https://github.com/thoughtbot/administrate
[easymde]: https://github.com/Ionaru/easy-markdown-editor
[zooppa]: https://www.zooppa.com/
