# https://github.com/rails/rails/pull/29180
require 'active_support'

module DatadogContextualizedLogs
  module ContextualizedController
    extend ActiveSupport::Concern

    DEFAULT_CONTEXTUALIZED_MODEL_ENABLED = false

    included do
      before_action :contextualize_requests, unless: -> { Rails.env.development? }
    end

    def contextualize_requests
     # store request && user info in CurrentContext ActiveSupport attribute
     # which can then be read from anywhere
     CurrentContext.model_context_values_enabled = self.class.contextualized_models_enabled?
     begin
       CurrentContext.resource_name = "#{self.class.name.downcase}_#{action_name.downcase}" rescue nil
       CurrentContext.request_uuid = request.uuid
       CurrentContext.request_origin = request.origin
       CurrentContext.request_user_agent = request.user_agent
       CurrentContext.request_referer = request.referer&.to_s
       CurrentContext.request_ip = request.ip
       CurrentContext.request_remote_ip = request.remote_ip
       CurrentContext.request_remote_addr = request.remote_addr
       CurrentContext.request_x_forwarded_for = request.x_forwarded_for
       CurrentContext.request_xhr = request.xhr? ? 'true' : 'false'
     rescue StandardError => e
       logger.dump_error('error setting context', e)
     end
    end

    def self.included(base)
      unless base.ancestors.include? ActionController::Base
        raise ArgumentError, "DatadogContextualizedLogs::ContextualizedController can only be included in a ActionController::Base"
      end

      base.extend(ClassMethods)
    end

    module ClassMethods
      def contextualized_models_enabled?
        @enable_contextualized_models || DEFAULT_CONTEXTUALIZED_MODEL_ENABLED
      end

      def enable_contextualized_models(enable)
        @enable_contextualized_models = enable
      end
    end

    private

    def logger
      Rails.logger
    end
  end
end
