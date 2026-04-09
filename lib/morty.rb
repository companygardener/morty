require "morty/engine"
require "morty/version"

module Morty
  autoload :Accountant, "morty/accountant"
  autoload :Adjustment, "morty/adjustment"
  autoload :Book,       "morty/book"
  autoload :Diff,       "morty/diff"
  autoload :DSL,        "morty/dsl"
  autoload :Error,      "morty/error"
  autoload :Event,      "morty/event"
  autoload :Rate,       "morty/rate"
  autoload :Source,     "morty/source"
  autoload :Schedule,  "morty/schedule"
  autoload :Seed,       "morty/seed"

  module Context
    autoload :Activity,   "morty/context/activity"
    autoload :Daily,      "morty/context/daily"
    autoload :Simulation, "morty/context/simulation"
  end

  module Cucumber
    autoload :Helpers,  "morty/cucumber/helpers"
    autoload :Steps,    "morty/cucumber/steps"
  end

  module List
    autoload :Activity, "morty/list/activity"
  end
end
