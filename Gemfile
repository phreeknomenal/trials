source "https://rubygems.org"

# Heroku's buildpack reads this directive to pick the runtime. Without it, it
# ignores .ruby-version and silently falls back to its own default series --
# the first deploy ran 3.3.9 while CI and local were on 3.4.x. Keep in sync
# with .ruby-version and .tool-versions.
ruby "3.4.10"

gem "activerecord-import"
gem "aws-sdk-s3", require: false
gem "anthropic"
gem "bootsnap", require: false
gem "cocoon"
gem "devise"
gem "faker"
gem "httparty"
gem "image_processing", "~> 2.0"
gem "importmap-rails"
gem "jbuilder"
gem "kamal", require: false
gem "pagy"
gem "propshaft"
gem "puma", ">= 5.0"
gem "pundit"
gem "rails", "~> 8.1.1"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "pg", "~> 1.5"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.4"
gem "tailwindcss-ruby", "~> 4.1"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "view_component"

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "standard", require: false
end

group :development do
  gem "annotaterb"
  gem "rails-erd"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
