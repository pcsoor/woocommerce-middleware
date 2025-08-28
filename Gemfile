source "https://rubygems.org"

gem "rails", "~> 8.0.2"

gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "devise"
gem 'faraday'
gem 'faraday-retry'
gem 'typhoeus'
gem "kaminari", "~> 1.2"
gem "tailwindcss-rails", "~> 4.2"
gem "roo", "~> 2.10"
gem 'rails-i18n', '~> 8.0.0'

gem "dotenv-rails", require: "dotenv/load"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails", "~> 8.0"
  gem "webmock", "~> 3.25"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "rails-controller-testing"
end

gem "rails_icons", "~> 1.3"

gem "dockerfile-rails", ">= 1.7", :group => :development
