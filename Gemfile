# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# CI pins these to exercise the supported range; see .github/workflows/build.yml.
gem 'administrate', ENV.fetch('ADMINISTRATE_VERSION', '>= 0.20')
gem 'rails', ENV.fetch('RAILS_VERSION', '>= 7.0')

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
