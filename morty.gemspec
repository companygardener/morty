require_relative "lib/morty/version"

Gem::Specification.new do |s|
  s.name          = "morty"
  s.version       = Morty::VERSION
  s.authors       = ["Erik Peterson"]
  s.email         = ["thecompanygardener@gmail.com"]
  s.summary       = %q{Morty is an accountant}
  s.description   = %q{}
  s.homepage      = "https://github.com/companygardener/morty"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.start_with?("bin/") }
  s.executables   = []
  s.require_paths = ["lib"]

  s.metadata["homepage_uri"]    = s.homepage
  s.metadata["source_code_uri"] = "https://github.com/companygardener/morty"
  s.add_dependency "railties",     ">= 7.0"
  s.add_dependency "activerecord", ">= 7.0"
  s.add_dependency "lookup_by"
  s.add_dependency "colorize"

  s.add_development_dependency "bundler", "~> 4.0"
  s.add_development_dependency "rake"    , "> 10.0"
end
