require "active_record/railtie"

require "lookup_by"

module Morty
  def self.table_name_prefix
    "morty."
  end

  class Engine < ::Rails::Engine
    isolate_namespace Morty
  end
end
