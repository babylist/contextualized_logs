class Model < ActiveRecord::Base
  include DatadogContextualizedLogs::ContextualizedModel
  contextualizable keys: { values: :value }
end
