# https://github.com/rails/rails/pull/29180
require 'active_support'
require_relative 'current_context'

module ContextualizedLogs
  module ContextualizedController
    extend ActiveSupport::Concern

    DEFAULT_CONTEXTUALIZED_MODEL_ENABLED = false
    DEFAULT_CURRENT_CONTEXT = ContextualizedLogs::CurrentContext

    included do
      before_action :contextualize_requests
    end

    def contextualize_requests
    # Rails.logger.debug "contextualize_requests"
     # store request && user info in CurrentContext ActiveSupport attribute
     # which can then be read from anywhere
     self.class.current_context.contextualized_model_enabled = self.class.contextualized_model_enabled?
     begin
       self.class.current_context.resource_name = "#{self.class.name.downcase}_#{action_name.downcase}" rescue nil
       self.class.current_context.request_uuid = request.uuid
       self.class.current_context.request_origin = request.origin
       self.class.current_context.request_user_agent = request.user_agent
       self.class.current_context.request_referer = request.referer&.to_s
       self.class.current_context.request_ip = request.ip
       self.class.current_context.request_remote_ip = request.remote_ip
       self.class.current_context.request_remote_addr = request.remote_addr
       self.class.current_context.request_x_forwarded_for = request.x_forwarded_for
       self.class.current_context.request_xhr = request.xhr? ? 'true' : 'false'
     rescue StandardError => e
       Rails.logger.dump_error('error setting context', e)
     end
    end

    def self.included(base)
      if !base.ancestors.include?(ActionController::Base) && !base.ancestors.include?(ActionController::API)
        raise ArgumentError, "ContextualizedLogs::ContextualizedController can only be included in a ActionController::Base or ActionController::API"
      end

      base.extend(ClassMethods)
    end

    module ClassMethods
      def contextualized_model_enabled?
        @contextualized_model_enabled || DEFAULT_CONTEXTUALIZED_MODEL_ENABLED
      end

      def contextualized_model(enable)
        @contextualized_model_enabled = enable
      end

      def current_context
        @current_context || DEFAULT_CURRENT_CONTEXT
      end

      def set_current_context(current_context)
        @current_context = current_context
      end
    end
  end
end
