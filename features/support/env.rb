puts "loading features/support/env"

require "timecop"
require_relative "../../spec/spec_helper"

Morty::Engine.load_seed

Before do
  ActiveRecord::Base.connection.begin_transaction(joinable: false)
end

After do
  ActiveRecord::Base.connection.rollback_transaction
  Timecop.return
end

require "morty/cucumber/steps"
