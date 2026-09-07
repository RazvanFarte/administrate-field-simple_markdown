# frozen_string_literal: true

# Minimal Administrate host application. It exists so the field is exercised
# the way a real dashboard uses it - through Administrate's own controllers,
# layout and asset registration - rather than only through unit specs.
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Both pipelines are supported, so both are testable. Only one may be loaded.
case ENV.fetch('ASSET_PIPELINE', 'sprockets')
when 'propshaft' then require 'propshaft'
else require 'sprockets/railtie'
end

require 'administrate/engine'
require 'administrate-field-easymde'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.eager_load = false
    config.secret_key_base = 'dummy-secret-key-base-for-tests-only'
    config.consider_all_requests_local = true
    config.hosts.clear
    config.logger = ActiveSupport::Logger.new(File.expand_path('../log/dummy.log', __dir__))

    config.autoload_paths << config.root.join('app/dashboards')

    # Serves the admin under a strict Content-Security-Policy when asked, so the
    # browser suite can prove the field needs neither 'unsafe-inline' scripts,
    # 'unsafe-eval', nor a third-party origin.
    #
    # script-src is the strict half and is what this gem is measured against.
    # style-src is relaxed because of code this gem does not own: CodeMirror 5
    # writes inline style attributes as it lays the editor out, and Administrate
    # 1.0's own bundle loads its CSS anchor positioning polyfill from a blob:
    # URL. Neither is fixable from here; both are documented in SECURITY.md.
    if ENV['STRICT_CSP'] == '1'
      config.action_dispatch.default_headers = config.action_dispatch.default_headers.merge(
        'Content-Security-Policy' => "default-src 'self'; script-src 'self'; " \
                                     "img-src 'self' data:; " \
                                     "style-src 'self' 'unsafe-inline' blob:"
      )
    end

    # Number of Markdown editors the article form renders, so the browser
    # benchmark can sweep it. See bench/browser_bench.mjs.
    config.x.editor_fields = Integer(ENV.fetch('EDITOR_FIELDS', '3'))
  end
end
