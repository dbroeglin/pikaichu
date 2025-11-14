# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.7"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 1.1.1"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# CSV support (removed from Ruby 3.4 stdlib)
gem "csv"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem 'devise'

gem "pundit"

# TODO: PG enums are supported in Rails 7.
# Warning: did not work because of add_enum_value
gem 'activerecord-postgres_enum', "~> 2.0"

gem 'country_select'

gem 'caxlsx', "3.1.0"

gem 'caxlsx_rails'

gem 'audited'

gem 'mobility', '~> 1.2.5'

gem "roo", "~> 2.8.0"

gem 'acts_as_list'

gem 'tabulo'

gem 'statesman', '~> 10.0.0'

gem 'kaminari'

gem 'capitalize-names'

gem "faraday", "~> 2.9"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "factory_bot_rails"
  gem 'faker'
  gem 'fixture_builder'

  gem 'foreman' # used to run bin/dev

  gem "azd", "~> 0.9", :group => :development
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-rails', require: false

  gem 'guard'
  gem 'guard-minitest'
  gem 'guard-rails'

  gem 'i18n-tasks', '~> 1.0.14'
  gem 'terminal-table'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'apparition'
  gem "capybara"
  gem "selenium-webdriver"
end
