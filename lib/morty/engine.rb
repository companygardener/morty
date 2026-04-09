require "active_record/railtie"

require "lookup_by"

module Morty
  def self.table_name_prefix
    "morty."
  end

  class Engine < ::Rails::Engine
    isolate_namespace Morty

    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path unless app.config.paths["db/migrate"].include?(path)
        end
      end
    end
  end
end
