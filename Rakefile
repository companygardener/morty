require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  if ENV["CI"]
    t.rspec_opts = "--format progress --format RspecJunitFormatter --out tmp/rspec.xml"
  end
end

require "cucumber/rake/task"
Cucumber::Rake::Task.new do |t|
  t.profile = ENV["CUCUMBER_PROFILE"] if ENV["CUCUMBER_PROFILE"]
end

task :db_setup do
  print "Preparing database..."
  ActiveRecord::Migration.verbose = false
  original_stdout = $stdout
  $stdout = File.open(File::NULL, "w")
  Rake::Task["app:db:prepare"].invoke
ensure
  $stdout = original_stdout
  puts " done"
end

task spec: :db_setup
task cucumber: :db_setup
task default: [:spec, :cucumber]

desc "Start a console with Morty loaded in the dummy app context"
task :console do
  ENV["APP_RAKEFILE"] = APP_RAKEFILE
  exec "irb -r #{File.expand_path("spec/dummy/config/environment", __dir__)}"
end
