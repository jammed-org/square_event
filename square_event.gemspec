$LOAD_PATH.push File.expand_path("lib", File.dirname(File.realpath(__FILE__)))

# Maintain your gem's version:
require "square_event/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "square_event"
  s.version     = SquareEvent::VERSION
  s.license     = "MIT"
  s.authors     = ["Andy Callaghan"]
  s.email       = "andy@andycallaghan.com"
  s.homepage    = "https://github.com/jammed-org/square_event"
  s.summary     = "Square webhook integration for Rails applications"
  s.description = "Square webhook integration for Rails applications"

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- Appraisals {spec,gemfiles}/*`.split("\n")

  s.add_dependency "activesupport", ">= 3.1"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "rails", [">= 3.1"]
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails", "~> 3.7"
  s.add_development_dependency "webmock", "~> 1.9"
end
