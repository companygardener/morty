ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"

require "rspec/rails"
require "rspec/its"

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start
end

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.backtrace_exclusion_patterns << /\.gem\//

  config.before(:suite) do
    ActiveRecord::Migration.maintain_test_schema!
    load Rails.root.join("db/seeds.rb")
  end
end

require "morty"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

class BigDecimal
  def inspect
    "%.2f" % self
  end
end
