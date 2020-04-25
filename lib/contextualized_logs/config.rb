
module ContextualizedLogs
  class Config
    DEFAULT_CURRENT_CONTEXT = CurrentContext
    DEFAULT_CONTROLLER_CONTEXTUALIZE_MODEL = false
    DEFAULT_WORKER_CONTEXTUALIZE_MODEL = false
    DEFAULT_WORKER_CONTEXTUALIZE_WORKER = true

    attr_accessor :log_formatter
    attr_accessor :current_context
    attr_accessor :controller_default_contextualizer
    attr_accessor :controller_default_contextualize_model
    attr_accessor :worker_default_contextualize_worker
    attr_accessor :worker_default_contextualize_model

    class << self
      def default
        config = new
        config.current_context = DEFAULT_CURRENT_CONTEXT
        config.controller_default_contextualize_model = DEFAULT_CONTROLLER_CONTEXTUALIZE_MODEL
        config.worker_default_contextualize_worker = DEFAULT_WORKER_CONTEXTUALIZE_MODEL
        config.worker_default_contextualize_model = DEFAULT_WORKER_CONTEXTUALIZE_WORKER
        config
      end
    end
  end
end
