require 'active_support'
require 'active_record'

module ContextualizedLogs
  module ContextualizedModel
    extend ActiveSupport::Concern

    class << self
      attr_writer :current_context

      def current_context
        @current_context || ContextualizedLogs.config.current_context
      end

      def included(base)
        unless base.ancestors.include? ActiveRecord::Base
          raise ArgumentError, "ContextualizedLogs::ContextualizedModel can only be included in a ActiveRecord::Base"
        end

        base.extend(ClassMethods)

        base.class_eval do
          after_find do |object|
            # Rails.logger.debug "after_find #{object}"
            ContextualizedModel.contextualize(object, self.class.contextualizable_keys, ContextualizedModel.current_context)
          end

          after_create do
            # Rails.logger.debug "after_create #{self}"
            ContextualizedModel.contextualize(self, self.class.contextualizable_keys, ContextualizedModel.current_context)
          end
        end
      end

      def contextualize(model, keys, context)
        # Rails.logger.debug "model: #{model}"
        # Rails.logger.debug "keys: #{keys}"
        # Rails.logger.debug "context.context: #{context}"
        # Rails.logger.debug "context.contextualize_model_enabled: #{context.contextualize_model_enabled}"
        return unless context.contextualize_model_enabled
        keys&.each do |k, v|
          v = model.try(v.to_sym)
          context.add_context(k, v) if v
        end
      end
    end

    module ClassMethods
      attr_reader :contextualizable_keys

      private

      def contextualizable(keys: {})
        @contextualizable_keys = keys
      end
    end
  end
end
