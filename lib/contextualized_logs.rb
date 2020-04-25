require "contextualized_logs/contextualized_logger"
require "contextualized_logs/contextualized_controller"
require "contextualized_logs/contextualized_model"
require "contextualized_logs/current_context"
require "contextualized_logs/sidekiq/middleware/client/inject_current_context"
require "contextualized_logs/sidekiq/middleware/server/restore_current_context"
require "contextualized_logs/contextualized_worker"
require "contextualized_logs/config"

module ContextualizedLogs
  require "contextualized_logs/railtie" if defined?(Rails)

  class << self
    attr_accessor :config

    def config
      @config || Config.default
    end

    def current_context
      config.current_context
    end

    def configure(&block)
      config = Config.default
      block.call(config)
      self.config = config
      ContextualizedLogger.formatter = config.log_formatter
      ContextualizedController.default_contextualizer = config.controller_default_contextualizer
      ContextualizedController.default_contextualize_model = config.controller_default_contextualize_model
      ContextualizedWorker.default_contextualize_model = config.worker_default_contextualize_model
      ContextualizedWorker.default_contextualize_worker = config.worker_default_contextualize_worker
      if defined?(Rails) && Rails.logger.is_a?(ContextualizedLogger)
        Rails.logger.formatter = config.log_formatter
      end
    end
  end
end

ContextualizedLogs.configure { |config| } # set default configuration
