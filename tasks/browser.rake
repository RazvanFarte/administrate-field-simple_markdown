# frozen_string_literal: true

require_relative 'support/dummy_server'

namespace :browser do
  desc 'Run the browser suite against the dummy app (Playwright in Docker)'
  task :test do
    editors = ENV.fetch('EDITOR_FIELDS', '3')
    passed = true

    { 'without a CSP' => '0', 'under a strict CSP' => '1' }.each do |description, csp|
      puts "\n== browser suite #{description} =="
      DummyServer.run('EDITOR_FIELDS' => editors, 'STRICT_CSP' => csp) do
        passed &= DummyServer.playwright(%w[--test spec/browser/editor_test.mjs],
                                         'EDITOR_FIELDS' => editors)
      end
    end

    abort 'browser suite failed' unless passed
  end
end
