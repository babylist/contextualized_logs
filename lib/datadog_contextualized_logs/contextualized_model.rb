require 'active_support'

module DatadogContextualizedLogs
  module ContextualizedModel
    extend ActiveSupport::Concern

    class_methods do
      attr_reader :contextualizable_keys

      private

      def contextualizable(keys: {})
        @contextualizable_keys = keys
      end
    end

    class << self
      def contextualize(model, keys)
        return unless CurrentContext.model_context_values_enabled
        keys&.each do |k, v|
          v = model.try(v.to_sym)
          CurrentContext.add_context(k, v) if v
        end
      end
    end

    included do
      after_find do |object|
        ContextualizedModel.contextualize(object, self.class.contextualizable_keys)
      end

      after_create do
        ContextualizedModel.contextualize(self, self.class.contextualizable_keys)
      end
    end
  end
end
