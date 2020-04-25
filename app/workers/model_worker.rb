class ModelWorker
  include Sidekiq::Worker
  include ContextualizedLogs::ContextualizedWorker
  contextualize_worker true
  contextualize_model true
  def self.contextualize_args(args)
    { model_id: args.first, action: args.last }
  end

  def perform(model_id, action)
    Model.find(model_id)
  end
end
