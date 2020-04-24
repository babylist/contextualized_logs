$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "datadog_contextualized_logs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "datadog_contextualized_logs"
  spec.version     = DatadogContextualizedLogs::VERSION
  spec.authors     = ["Hugues Bernet-Rollande"]
  spec.email       = ["hugues@xdev.fr"]
  spec.homepage    = "https://github.com/hugues/datadog_contextualized_logs"
  spec.summary     = "Summary of DatadogContextualizedLogs."
  spec.description = "Description of DatadogContextualizedLogs."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.2.3"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rails", "~> 5.2.3"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rspec-core", '~> 3.8'
  spec.add_development_dependency  'rspec-mocks', '~> 3.8'
  spec.add_development_dependency  'rspec-rails', '~> 3.8'
  # spec.add_development_dependency  'simplecov' #, '0.12.0' # Code coverage reporting
  spec.add_development_dependency  'timecop', '~> 0.8'
  spec.add_development_dependency   'faker', '~> 1.8'
end
