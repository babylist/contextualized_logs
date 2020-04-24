# coding: utf-8
require "rails_helper"

class DummyController < ActionController::Base
   include ContextualizedLogs::ContextualizedController

   def show
     Model.last
     render json: {}
   end
end

RSpec.describe DummyController, type: :controller do
  let(:params) { { a: 'a' } }
  let!(:model) { FactoryBot.create(:model, value: 'value') }

  before do
    Rails.application.routes.draw {
      get 'dummy' => 'dummy#show'
    }
  end

  it 'should set request details' do
    expect_any_instance_of(DummyController).to receive(:contextualize_requests)
    get :show, params: params
  end

  it 'should NOT set enable model context values' do
    get :show, params: params
    expect(ContextualizedLogs::CurrentContext.contextualized_model_enabled).to eq(false)
    expect(ContextualizedLogs::CurrentContext.context_values).to eq(nil)
  end

  it 'should set resource_name' do
    get :show, params: params
    expect(ContextualizedLogs::CurrentContext.resource_name).to eq('dummycontroller_show')
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

    expect(ContextualizedLogs::CurrentContext.request_uuid).to eq('request_uuid')
    expect(ContextualizedLogs::CurrentContext.request_origin).to eq('origin')
    expect(ContextualizedLogs::CurrentContext.request_referer).to eq('referer')
    expect(ContextualizedLogs::CurrentContext.request_remote_addr).to eq('192.168.0.0')
    expect(ContextualizedLogs::CurrentContext.request_remote_ip).to eq('192.168.0.1')
    expect(ContextualizedLogs::CurrentContext.request_ip).to eq('192.168.0.2')
    expect(ContextualizedLogs::CurrentContext.request_x_forwarded_for).to eq(['192.168.0.3', '192.168.0.4'])
    expect(ContextualizedLogs::CurrentContext.request_xhr).to eq('true')
  end
end

class ContextualizedModelsDummyController < ActionController::Base
   include ContextualizedLogs::ContextualizedController
   contextualized_models true

   def show
     Model.last
     render json: {}
   end
end

RSpec.describe ContextualizedModelsDummyController, type: :controller do
  let(:params) { { a: 'a' } }
  let!(:model) { FactoryBot.create(:model, value: 'value') }
  before do
    routes.draw {
      get 'dummy' => 'contextualized_models_dummy#show'
    }
  end

  it 'should set request details' do
    expect_any_instance_of(ContextualizedModelsDummyController).to receive(:contextualize_requests)
    get :show, params: params
  end

  it 'should set enable model context values' do
    get :show, params: params
    expect(ContextualizedLogs::CurrentContext.contextualized_model_enabled).to eq(true)
    expect(ContextualizedLogs::CurrentContext.context_values).to eq(values: ['value'])
  end
end
