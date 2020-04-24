require 'active_support'

module ContextualizedLogs
  module ContextualizedWorker
    extend ActiveSupport::Concern

    DEFAULT_CURRENT_CONTEXT = ContextualizedLogs::CurrentContext
    DEFAULT_CONTEXTUALIZED_WORKER_ENABLED = false
    DEFAULT_CONTEXTUALIZED_MODEL_ENABLED = false

    class_methods do
      # contextualize_args

      def current_context
        @current_context || DEFAULT_CURRENT_CONTEXT
      end

      def contextualized_worker_enabled
        @contextualized_worker_enabled || DEFAULT_CONTEXTUALIZED_WORKER_ENABLED
      end

      def contextualized_model_enabled
        @contextualized_model_enabled || DEFAULT_CONTEXTUALIZED_MODEL_ENABLED
      end

      private

      def set_current_context(current_context)
        @current_context = current_context
      end

      def contextualized_worker(enabled)
        @contextualized_worker_enabled = enabled
      end

      def contextualized_model(enabled)
        @contextualized_model_enabled = enabled
      end
    end
  end
end
