require 'active_support'
require 'sidekiq'

module ContextualizedLogs
  module ContextualizedWorker
    extend ActiveSupport::Concern

    class << self
      attr_writer :current_context
      attr_writer :default_contextualize_model
      attr_writer :default_contextualize_worker

      def current_context
        @current_context || ContextualizedLogs.config.current_context
      end

      def default_contextualize_model
        @default_contextualize_model || ContextualizedLogs.config.worker_default_contextualize_model
      end

      def default_contextualize_worker
        @default_contextualize_worker || ContextualizedLogs.config.worker_default_contextualize_worker
      end

      def included(base)
        unless base.ancestors.include? ::Sidekiq::Worker
          raise ArgumentError, "ContextualizedLogs::ContextualizedWorker can only be included in a Sidekiq::Worker"
        end

        base.extend(ClassMethods)

        # Automatically add sidekiq middleware when we're first included
        #
        # This might only occur when the worker class is first loaded in a
        # development rails environment, but that happens before the middleware
        # chain is invoked so we're all good.
        #
        ::Sidekiq.configure_server do |config|
          unless config.server_middleware.exists? Sidekiq::Middleware::Server::RestoreCurrentContext
            config.server_middleware.add Sidekiq::Middleware::Server::RestoreCurrentContext
          end
        end
        ::Sidekiq.configure_client do |config|
          unless config.client_middleware.exists? Sidekiq::Middleware::Client::InjectCurrentContext
            config.client_middleware.add Sidekiq::Middleware::Client::InjectCurrentContext
          end
        end
      end
    end

    module ClassMethods
      def contextualize_worker_enabled
        return @contextualize_worker_enabled if defined?(@contextualize_worker_enabled)

        ContextualizedWorker.default_contextualize_worker
      end

      def contextualize_model_enabled
        return @contextualize_model_enabled if defined?(@contextualize_model_enabled)

        ContextualizedWorker.default_contextualize_model
      end

      private

      def contextualize_worker(enabled)
        @contextualize_worker_enabled = enabled
      end

      def contextualize_model(enabled)
        @contextualize_model_enabled = enabled
      end
    end
  end
end
