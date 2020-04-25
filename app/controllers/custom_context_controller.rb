class CustomContextController < ApplicationController
  include ContextualizedLogs::ContextualizedController

  def contextualize_request(controller)
    super(controller)

    ContextualizedLogs::ContextualizedController.current_context.custom_attributes = {
      http: {
        service: 'rails'
      }
    }
  end

  def show
    render json: {}, status: 200
  end
end
