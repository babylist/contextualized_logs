
require "rails/railtie"
require 'rails'

module DatadogContextualizedLogs
  class Railtie < ::Rails::Railtie
    railtie_name :datadog_contextualized_logs
  end
end
