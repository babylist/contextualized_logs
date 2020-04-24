require "datadog_contextualized_logs/contextualized_logger"
require "datadog_contextualized_logs/contextualized_controller"
require "datadog_contextualized_logs/contextualized_model"
require "datadog_contextualized_logs/current_context"

module DatadogContextualizedLogs
  require "datadog_contextualized_logs/railtie" if defined?(Rails)
end
