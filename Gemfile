# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# CI pins these to exercise the supported range; see .github/workflows/build.yml.
gem 'administrate', ENV.fetch('ADMINISTRATE_VERSION', '>= 0.20')
gem 'rails', ENV.fetch('RAILS_VERSION', '>= 7.0')

# json 3.0 added strict keyword validation to JSON.generate. ActiveSupport
# 7.2's JSON encoder still passes the long-inert `quirks_mode:` keyword,
# which json <3 silently ignored and json >=3 now raises ArgumentError on -
# "unknown keyword: quirks_mode" - breaking every #easymde_options call on
# the Rails 7.2 end of the range this gem supports. ActiveSupport 8 dropped
# that keyword, so this only bites the floor of the range, not the ceiling.
gem 'json', '< 3'

group :development, :test do
  gem 'overcommit', '~> 0.64'
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.75'
  gem 'rubocop-rspec', '~> 3.5'
end

group :test do
  gem 'capybara', '~> 3.40'
  gem 'puma', '~> 6.6'
  gem 'rspec-rails', '~> 7.1'
  # Both pipelines are installed so the dummy app can be booted under either;
  # spec/dummy/config/application.rb requires exactly one of them.
  gem 'propshaft', '~> 1.1'
  gem 'sprockets-rails', '~> 3.5'
  gem 'sqlite3', '~> 2.6'
end

group :benchmark do
  gem 'benchmark-ips', '~> 2.14'
  gem 'pg', '~> 1.5'
end
