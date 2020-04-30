$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "contextualized_logs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "contextualized_logs"
  spec.version     = ContextualizedLogs::VERSION
  spec.authors     = ["Hugues Bernet-Rollande"]
  spec.email       = ["engineering@babylist.com"]
  spec.homepage    = "https://github.com/babylist/contextualized_logs"
  spec.metadata    = {
    "homepage_uri" =>  "https://github.com/babylist/contextualized_logs",
    "source_code_uri" => "https://github.com/babylist/contextualized_logs"
  }
  spec.summary     = "Contextualize your logs (requests params, found/created model metadata, workers, ...)"
  spec.description = <<~EOF
  Online logging solution (like [Datadog](https://www.datadoghq.com)) have drastically transform the way we log.

  An app will nowdays logs dozen (hundred) of logs per requests.

  The issue is often to correlate this logs, with the initiating request (or job) and add shared metadata on this logs.

  Here come `ContextualizedLogs`.

  The main idea is to enhance your logs from your controller (including `ContextualizedController`, which use a before action), which will add the params to your logs (and some metadata about the request itself, like `request.uuid`).

  This metadata are stored in a `ActiveSupport::CurrentAttributes` which is a singleton (reset per request).

  Each subsequent logs in this thread (request) will also be enriched with this metadata, making it easier to find all the logs associated with a request (`uuid`, `ip`, `params.xxx`).

  On top of this, logs can also be enriched by the ActiveRecord model they use (`create` or `find`) (models including `ContextualizedModel`). So any time a contextualized model is created or find, some metadata related to the model (`id`, ...) will also be added to the logs.

  Allowing you to find all logs which "touched" this models.
  EOF
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  # spec.add_dependency "rails", "~> 5.2.3"
  #
  # spec.add_development_dependency "bundler", "~> 2.0"
  # spec.add_development_dependency "rake", "~> 13.0"
  # spec.add_development_dependency "rails", "~> 5.2.3"
  # spec.add_development_dependency "sqlite3"
  # spec.add_development_dependency "rspec", "~> 3.8"
  # spec.add_development_dependency "rspec-core", '~> 3.8'
  # spec.add_development_dependency  'rspec-mocks', '~> 3.8'
  # spec.add_development_dependency  'rspec-rails', '~> 3.8'
  # # spec.add_development_dependency  'simplecov' #, '0.12.0' # Code coverage reporting
  # spec.add_development_dependency  'timecop', '~> 0.8'
  # spec.add_development_dependency   'faker', '~> 1.8'
end
