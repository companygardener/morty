require_relative "boot"

require "rails"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require "morty"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    config.autoload_lib(ignore: %w[assets tasks]) if config.respond_to?(:autoload_lib)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use SQL format for schema dumps (required for PostgreSQL schemas, triggers, functions)
    config.active_record.schema_format = :sql
    config.active_record.dump_schemas = "morty,morty_archive"
    config.active_record.dump_schema_after_migration = false
  end
end
