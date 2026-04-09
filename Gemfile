source "https://rubygems.org"

# Specify your gem's dependencies in morty.gemspec
gemspec

gem "rails"
gem "lookup_by", github: "companygardener/lookup_by"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "appraisal", "~> 2.5.0"

group :development, :test do
  gem "rspec-rails"

  gem "pg"
  gem "puma"
  gem "propshaft"
end

group :test do
  gem "rspec-its"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "cucumber"
  gem "simplecov", require: false
  gem "rspec_junit_formatter"
  gem "timecop"
  gem "chronic"
end
