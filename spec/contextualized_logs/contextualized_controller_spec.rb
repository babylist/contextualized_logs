# coding: utf-8
require "rails_helper"

class DummyController < ActionController::Base
   include ContextualizedLogs::ContextualizedController

   def show
     Model.last
     render json: {}
   end
end

class ContextualizedModelDummyController < ActionController::Base
   include ContextualizedLogs::ContextualizedController
   contextualize_model true

   def show
     Model.last
     render json: {}
   end
end

RSpec.describe DummyController, type: :controller do
  let(:params) { { a: 'a' } }
  let!(:model) { FactoryBot.create(:model, value: 'value') }
  let(:current_context) { ContextualizedLogs::CurrentContext }

  before do
    Rails.application.routes.draw {
      get 'dummy' => 'dummy#show'
    }
  end

  it 'should set request details' do
    expect_any_instance_of(DummyController).to receive(:contextualize_request)
    get :show, params: params
  end

  it 'should NOT set enable model context values' do
    get :show, params: params
    expect(current_context.contextualize_model_enabled).to eq(false)
    expect(current_context.context_values).to eq(nil)
  end

  it 'should set resource_name' do
    get :show, params: params
    expect(current_context.resource_name).to eq('dummycontroller_show')
  end

  it 'should set request details' do
    %w[user-agent referer origin].each do |header|
        @request.headers[header] = header
    end
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_addr).and_return('192.168.0.0')
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return('192.168.0.1')
    allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('192.168.0.2')
    allow_any_instance_of(ActionDispatch::Request).to receive(:x_forwarded_for).and_return(['192.168.0.3', '192.168.0.4'])
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    allow_any_instance_of(ActionDispatch::Request).to receive(:uuid).and_return('request_uuid')

    get :show, params: params

    expect(current_context.request_uuid).to eq('request_uuid')
    expect(current_context.request_origin).to eq('origin')
    expect(current_context.request_referer).to eq('referer')
    expect(current_context.request_remote_addr).to eq('192.168.0.0')
    expect(current_context.request_remote_ip).to eq('192.168.0.1')
    expect(current_context.request_ip).to eq('192.168.0.2')
    expect(current_context.request_x_forwarded_for).to eq(['192.168.0.3', '192.168.0.4'])
    expect(current_context.request_xhr).to eq('true')
  end
end

RSpec.describe ContextualizedModelDummyController, type: :controller do
  let(:params) { { a: 'a' } }
  let!(:model) { FactoryBot.create(:model, value: 'value') }
  let(:current_context) { ContextualizedLogs::CurrentContext }

  before do
    routes.draw {
      get 'dummy' => 'contextualized_model_dummy#show'
    }
  end

  it 'should set request details' do
    expect_any_instance_of(ContextualizedModelDummyController).to receive(:contextualize_request)
    get :show, params: params
  end

  it 'should set enable model context values' do
    get :show, params: params
    expect(current_context.contextualize_model_enabled).to eq(true)
    expect(current_context.context_values).to eq(model_values: ['value'], model_ids: [model.id])
  end
end
