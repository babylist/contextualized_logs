# https://github.com/rails/rails/pull/29180
require 'active_support'
require 'action_controller'

module ContextualizedLogs
  module ContextualizedController
    extend ActiveSupport::Concern

    class << self
      attr_accessor :default_contextualizer
      attr_writer :default_contextualize_model
      attr_writer :current_context

      def current_context
        @current_context || ContextualizedLogs.config.current_context
      end

      def default_contextualize_model
        @default_contextualize_model || ContextualizedLogs.config.controller_default_contextualize_model
      end

      def included(base)
        if !base.ancestors.include?(ActionController::Base) && !base.ancestors.include?(ActionController::API)
          raise ArgumentError, "ContextualizedLogs::ContextualizedController can only be included in a ActionController::Base or ActionController::API"
        end

        base.class_eval do
          before_action do |controller|
            contextualize_request(controller)
          end
        end

        base.extend(ClassMethods)
      end

      def default_contextualize_request(controller)
        # Rails.logger.debug "contextualize_request"
        # store request && user info in CurrentContext ActiveSupport attribute
        # which can then be read from anywhere
        ContextualizedController.current_context.contextualize_model_enabled = controller.class.contextualize_model_enabled?
        ContextualizedController.current_context.resource_name = "#{controller.class.name.downcase}_#{controller.action_name.downcase}" rescue nil
        ContextualizedController.current_context.request_uuid = controller.request.uuid
        ContextualizedController.current_context.request_origin = controller.request.origin
        ContextualizedController.current_context.request_user_agent = controller.request.user_agent
        ContextualizedController.current_context.request_referer = controller.request.referer&.to_s
        ContextualizedController.current_context.request_ip = controller.request.ip
        ContextualizedController.current_context.request_remote_ip = controller.request.remote_ip
        ContextualizedController.current_context.request_remote_addr = controller.request.remote_addr
        ContextualizedController.current_context.request_x_forwarded_for = controller.request.x_forwarded_for
        ContextualizedController.current_context.request_xhr = controller.request.xhr? ? 'true' : 'false'
      end
    end

    def contextualize_request(controller)
      if ContextualizedController.default_contextualizer
        ContextualizedController.default_contextualizer.call(controller)
        return
      end

      ContextualizedController.default_contextualize_request(controller)
    rescue StandardError => e
       Rails.logger.dump_error('error setting controller context', e)
    end

    module ClassMethods
      def contextualize_model_enabled?
        return @contextualize_model_enabled if defined?(@contextualize_model_enabled)

        ContextualizedController.default_contextualize_model
      end

      def contextualize_model(enable)
        @contextualize_model_enabled = enable
      end
    end
  end
end
