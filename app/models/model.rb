class Model < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel
  contextualizable keys: { model_ids: :id, model_values: :value }
end
