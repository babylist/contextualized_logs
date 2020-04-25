# coding: utf-8
require "rails_helper"

RSpec.describe CustomContextController, type: :controller do
  let(:current_context) { ContextualizedLogs::CurrentContext }

  before do
    Rails.application.routes.draw {
      get 'custom_context' => 'custom_context#show'
    }
  end

  it 'should set request details' do
    expect_any_instance_of(CustomContextController).to receive(:contextualize_request)
    get :show
  end

  it 'should set custom attributes' do
    get :show
    expect(current_context.custom_attributes).to eq(
      http: {
        service: 'rails'
      }
    )
  end
end
