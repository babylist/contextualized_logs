require "contextualized_logs/contextualized_logger"
require "contextualized_logs/contextualized_controller"
require "contextualized_logs/contextualized_model"
require "contextualized_logs/current_context"

module ContextualizedLogs
  require "contextualized_logs/railtie" if defined?(Rails)
end
