class CreateMortySchema < ActiveRecord::Migration[7.0]
  def up
    original_search_path = execute("SHOW search_path").first['search_path']

    begin
      execute Morty::Engine.root.join("db/sql/create_morty_schema.sql").read
    ensure
      connection.execute("SET search_path TO #{original_search_path}")
    end
  end

  def down
    raise "this will drop the morty schema, run with UNSAFE_MIGRATION=true to execute" unless ENV["UNSAFE_MIGRATION"]

    drop_schema :morty
  end
end
