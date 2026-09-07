# frozen_string_literal: true

require_relative 'lib/administrate_field_easymde/version'

Gem::Specification.new do |gem|
  gem.name = 'administrate-field-easymde'
  gem.version = AdministrateFieldEasymde::VERSION
  gem.authors = ['Razvan Dan Farte']
  gem.email = ['farterazvan@gmail.com']
  gem.homepage = 'https://github.com/RazvanFarte/administrate-field-simple_markdown'
  gem.summary = 'Markdown editor field for Administrate, powered by EasyMDE'
  gem.description = <<~DESCRIPTION.tr("\n", ' ').strip
    An Administrate field that edits Markdown with EasyMDE and renders it with
    Redcarpet. A maintained fork of administrate-field-simple_markdown by
    Zooppa, updated for Administrate 1.0 and Rails 8, with no jQuery, no eval,
    and no third-party CDN requests.
  DESCRIPTION
  gem.license = 'MIT'

  gem.metadata = {
    'homepage_uri' => gem.homepage,
    'source_code_uri' => gem.homepage,
    'changelog_uri' => "#{gem.homepage}/blob/main/CHANGELOG.md",
    'bug_tracker_uri' => "#{gem.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }

  gem.required_ruby_version = '>= 3.1'

  gem.require_paths = ['lib']
  gem.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |path|
      path.start_with?('spec/', 'build/', 'bench/', '.github/', '.') ||
        %w[Gemfile Rakefile package.json package-lock.json demo.gif].include?(path)
    end
  end

  # Deliberately not depending on the `rails` meta-gem: this only needs the
  # engine machinery and the view helpers, and depending on all of Rails is what
  # made the previous version uninstallable on Rails 7.1+ (through a `rack ~> 2`
  # pin that Rails 8 cannot satisfy).
  gem.add_dependency 'actionview', '>= 7.0', '< 9.0'
  gem.add_dependency 'activesupport', '>= 7.0', '< 9.0'
  gem.add_dependency 'administrate', '>= 0.20', '< 2.0'
  gem.add_dependency 'railties', '>= 7.0', '< 9.0'
  gem.add_dependency 'redcarpet', '~> 3.6'
end
