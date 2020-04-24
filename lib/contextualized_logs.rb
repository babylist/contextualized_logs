require "contextualized_logs/contextualized_logger"
require "contextualized_logs/contextualized_controller"
require "contextualized_logs/contextualized_model"
require "contextualized_logs/current_context"
require "contextualized_logs/sidekiq/middleware/client/inject_current_context"
require "contextualized_logs/sidekiq/middleware/server/restore_current_context"
require "contextualized_logs/contextualized_worker"

module ContextualizedLogs
  require "contextualized_logs/railtie" if defined?(Rails)
end
