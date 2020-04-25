class ModelController < ApplicationController
  include ContextualizedLogs::ContextualizedController
  contextualize_model true

  def index
    models = Model.all.map { |model| { id: model.id, value: model.value} }
    render json: { models: models }, status: 200
  end

  def show
    model = Model.find(params[:id])
    ModelWorker.perform_async(model.id, 'show')
    render json: { models: { id: model.id, value: model.value} }, status: 200
  end

  def destroy
    Model.find(params[:id]).destroy!
    render json: { success: 'true' }, status: 200
  end

  def create
    model = Model.create(value: params[:value])
    ModelWorker.perform_async(model.id, 'create')
    render json: { models: { id: model.id, value: model.value} }, status: 201
  end
end
