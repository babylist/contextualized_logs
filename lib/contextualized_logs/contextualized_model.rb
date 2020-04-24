require 'active_support'
require_relative 'current_context'

module ContextualizedLogs
  module ContextualizedModel
    extend ActiveSupport::Concern

    DEFAULT_CURRENT_CONTEXT = ContextualizedLogs::CurrentContext

    class_methods do
      attr_reader :contextualizable_keys

      def current_context
        @current_context || DEFAULT_CURRENT_CONTEXT
      end

      private

      def contextualizable(keys: {})
        @contextualizable_keys = keys
      end

      def set_current_context(current_context)
        @current_context = current_context
      end
    end

    class << self
      def contextualize(model, keys, context)
        return unless context.contextualized_model_enabled
        keys&.each do |k, v|
          v = model.try(v.to_sym)
          context.add_context(k, v) if v
        end
      end
    end

    included do
      after_find do |object|
        ContextualizedModel.contextualize(object, self.class.contextualizable_keys, self.class.current_context)
      end

      after_create do
        ContextualizedModel.contextualize(self, self.class.contextualizable_keys, self.class.current_context)
      end
    end
  end
end
