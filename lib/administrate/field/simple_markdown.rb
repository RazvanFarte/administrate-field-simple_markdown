# frozen_string_literal: true

require 'administrate/field/text'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/string/filters'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/string/output_safety'
require 'redcarpet'
require 'redcarpet/render_strip'

module Administrate
  module Field
    class SimpleMarkdown < Administrate::Field::Text
      # Number of characters shown by the index partial before truncation.
      # Matches Rails' own `truncate` default, which is what this field used
      # before the preview was rendered separately.
      DEFAULT_TRUNCATE_LENGTH = 30

      # Rendering a 10,000 character document only to throw all but 30
      # characters of it away is the dominant cost of an index page with a
      # Markdown column, so #preview strips a slice of the raw source instead.
      # The slice is generous because stripping Markdown shrinks the text:
      # "[link](https://example.com/a/long/path)" is 39 characters of source
      # and 4 characters of output.
      PREVIEW_SOURCE_MULTIPLIER = 4
      PREVIEW_SOURCE_MINIMUM = 256

      # Class prefix EasyMDE puts on every toolbar button, so that the bundled
      # stylesheet can draw the icons. Must match build/build_assets.mjs.
      TOOLBAR_BUTTON_CLASS_PREFIX = 'administrate-easymde'

      # EasyMDE reaches out to two CDNs out of the box: a Font Awesome
      # stylesheet for the toolbar icons, and a ~600 KB spell-check dictionary.
      # Both are third-party requests from every admin form page, both fail
      # under a strict Content-Security-Policy, and both are avoidable - the
      # gem bundles its own icons, and browsers have spell-checked textareas
      # natively for years. Either can be turned back on per field.
      EASYMDE_DEFAULTS = {
        'autoDownloadFontAwesome' => false,
        'spellChecker' => false
      }.freeze

      HTML_RENDERER_DEFAULTS = {
        safe_links_only: true,
        filter_html: true,
        with_toc_data: true,
        hard_wrap: true,
        link_attributes: { rel: 'nofollow' }
      }.freeze

      MARKDOWN_DEFAULTS = {
        autolink: true,
        tables: true,
        no_intra_emphasis: true,
        strikethrough: true,
        highlight: true,
        space_after_headers: true
      }.freeze

      def data
        @data || ''
      end

      # Serialized into a data attribute and read back by the bundled
      # JavaScript. Keys are camelized because that is what EasyMDE expects,
      # while Ruby dashboards are written in snake_case.
      def easymde_options
        configured = options.fetch(:easymde_options, {})
                            .transform_keys { |key| key.to_s.camelize(:lower) }

        EASYMDE_DEFAULTS.merge(toolbar_button_class_prefix(configured))
                        .merge(configured)
                        .to_json
      end

      def input_options
        user_options = options.fetch(:input_options, {})
        data_options = user_options.fetch(:data, {}).merge(easymde_options: easymde_options)

        user_options.merge(data: data_options)
      end

      # The result is marked html_safe, so everything that can inject markup has
      # to be closed off before this returns. Two layers do that: Redcarpet's
      # own filter_html/safe_links_only, and - if a dashboard turns filter_html
      # off to allow some HTML through - Rails' allow-list sanitizer.
      def to_html
        html = markdown(html_renderer).render(data)
        html = sanitize(html) if sanitize?

        html.html_safe
      end

      # True unless Redcarpet is already stripping HTML, so that turning
      # filter_html off downgrades from "no HTML" to "allow-listed HTML"
      # rather than to "whatever the author typed". Pass sanitize: false to
      # opt out deliberately.
      def sanitize?
        options.fetch(:sanitize) { !options.fetch(:filter_html, true) }
      end

      def to_s
        markdown(plaintext_renderer).render(data)
      end

      # Plain-text summary for the index page. See PREVIEW_SOURCE_MULTIPLIER
      # for why this does not simply truncate #to_s.
      def preview(length: truncate_length)
        source = data
        limit = preview_source_limit(length)
        source = source[0, limit] if limit

        # Collapsed to one line: an index cell is a single line of text, and
        # StripDown keeps the source's paragraph breaks.
        markdown(plaintext_renderer).render(source).gsub(/\s+/, ' ').strip.truncate(length)
      end

      def truncate_length
        options.fetch(:truncate_length, DEFAULT_TRUNCATE_LENGTH)
      end

      # Kept for dashboards and view overrides that referenced it. The bundled
      # JavaScript no longer needs it: it finds editors by data attribute, which
      # also works for fields rendered more than once on a page.
      def html_id
        [
          resource.class.name.underscore.gsub('/', '_'),
          attribute
        ].join('_')
      end

      private

      # Only claim the toolbar button classes when the bundled icons are the
      # ones being drawn. A dashboard that asks for Font Awesome back gets
      # EasyMDE's own class names, and the bundled icon rules stop matching.
      def toolbar_button_class_prefix(configured)
        return {} if configured['autoDownloadFontAwesome']

        { 'toolbarButtonClassPrefix' => TOOLBAR_BUTTON_CLASS_PREFIX }
      end

      def sanitize(html)
        require 'action_view'

        ActionView::Base.safe_list_sanitizer.sanitize(
          html,
          **{
            tags: options[:sanitize_tags],
            attributes: options[:sanitize_attributes]
          }.compact
        )
      end

      def preview_source_limit(length)
        options.fetch(:preview_source_limit) do
          [length * PREVIEW_SOURCE_MULTIPLIER, PREVIEW_SOURCE_MINIMUM].max
        end
      end

      def html_renderer
        @html_renderer ||= Redcarpet::Render::HTML.new(
          HTML_RENDERER_DEFAULTS.to_h { |key, default| [key, options.fetch(key, default)] }
        )
      end

      def plaintext_renderer
        Redcarpet::Render::StripDown
      end

      # Keyed by renderer: a single field instance renders both HTML (#to_html)
      # and plain text (#to_s), and memoizing one Redcarpet::Markdown for both
      # meant whichever was called second silently reused the first one's
      # renderer.
      def markdown(renderer)
        @markdown ||= {}
        @markdown[renderer] ||= Redcarpet::Markdown.new(
          renderer,
          MARKDOWN_DEFAULTS.to_h { |key, default| [key, options.fetch(key, default)] }
        )
      end
    end
  end
end

require 'administrate_field_easymde/engine'
