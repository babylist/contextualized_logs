class Model < ActiveRecord::Base
  include ContextualizedLogs::ContextualizedModel
  contextualizable keys: { values: :value }
end
