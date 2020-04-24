require 'rails_helper'
# require 'json'
require 'sidekiq/testing'

module ContextualizedLogs
  RSpec.describe Sidekiq::Middleware::Server::RestoreCurrentContext do
    class DummyWorker
      include ::Sidekiq::Worker

      def perform
      end
    end

    class ContextualizedDummyWorker < DummyWorker
      include ContextualizedWorker
      contextualized_worker true
    end

    class ContextualizedModelDummyWorker < DummyWorker
      include ContextualizedWorker
      contextualized_worker true
      contextualized_model true
    end

    class ContextualizedArgsDummyWorker < DummyWorker
      include ContextualizedWorker
      contextualized_worker true

      def self.contextualize_args(args)
        { first: args.first }
      end
    end

    subject { described_class.new }
    let(:pipe) { IO.pipe }
    let(:write) { pipe[1] }
    let(:read) { pipe[0] }
    let(:raw_logs) do
      buffer = ''
      write.close
      until read.eof?
        buffer += read.read(2048)
      end
      buffer
    end
    let(:logs) { raw_logs.split("\n").map { |log| JSON.parse(log).deep_symbolize_keys } }
    let(:current_context) { CurrentContext }
    let(:worker_class) { DummyWorker }

    before do
      contextualized_logger = ContextualizedLogger.new(write)
      allow(Rails).to receive(:logger).and_return(contextualized_logger)
    end

    RSpec.shared_examples 'it yield' do
      it do
        yielded = false
        worker = worker_class.new
        subject.call(worker, {}, nil) do
          yielded = true
        end
        expect(yielded).to eq(true)
      end
    end

    RSpec.shared_examples 'restore context' do
      it 'restore context' do
        job = {'jid' => 1, 'context' => { request_uuid: 1 }.to_json}
        worker = worker_class.new
        subject.call(worker, job, nil) do
          expect(current_context.request_uuid).to eq(1)
        end
      end
    end

    RSpec.shared_examples 'log job failure' do
      it 'log job failure' do
        expect(Rails.logger).to receive(:error).with("sidekiq: failure job #{worker_class}: 1, on queue : StandardError")
        job = {'jid' => 1}
        worker = worker_class.new
        expect {
          subject.call(worker, job, nil) do
            raise StandardError
          end
        }.to raise_error StandardError
      end
    end

    RSpec.shared_examples 'log with context' do
      it 'log with context' do
        job = {'jid' => 1, 'context' => { request_uuid: 1 }.to_json}
        worker = worker_class.new
        subject.call(worker, job, 'queue') {}
        log = logs.first
        expect(log[:message]).to eq("sidekiq: performing job #{worker_class}: 1, on queue queue")
        expect(log[:job][:id]).to eq(1)
        expect(log[:job][:worker]).to eq(worker_class.to_s)
        expect(log[:http][:request_id]).to eq(1)
        log = logs.last
        expect(log[:message]).to eq("sidekiq: completing job #{worker_class}: 1, on queue queue")
        expect(log[:job][:id]).to eq(1)
        expect(log[:job][:worker]).to eq(worker_class.to_s)
        expect(log[:http][:request_id]).to eq(1)
      end
    end

    RSpec.shared_examples 'enable model context values' do |enabled, values|
      it 'enable model context values' do
        model_id = FactoryBot.create(:model, value: 'value').id
        job = {'jid' => 1, 'context' => {request_uuid: 1}.to_json}
        worker = worker_class.new
        subject.call(worker, job, nil) do
          Model.find(model_id)
        end
        expect(current_context.context_values).to eq(values)
        expect(current_context.contextualized_model_enabled).to eq(enabled)
      end
    end

    context 'with uncontextualized worker' do
      let(:worker_class) { DummyWorker }

      it_behaves_like 'it yield'

      it 'DOES NOT log job' do
        expect(Rails.logger).not_to receive(:info).with('sidekiq: performing job ContextualizedLogs::DummyWorker: 1, on queue ')
        expect(Rails.logger).not_to receive(:info).with('sidekiq: completing job ContextualizedLogs::DummyWorker: 1, on queue ')
        job = {'jid' => 1}
        worker = worker_class.new
        subject.call(worker, job, nil) do
        end
      end

      it 'DOES NOT log job failure' do
        expect(Rails.logger).not_to receive(:error)
        job = {'jid' => 1}
        worker = worker_class.new
        expect {
          subject.call(worker, job, nil) do
            raise StandardError
          end
        }.to raise_error StandardError
      end

      it_behaves_like 'enable model context values', nil, nil
    end

    context 'with contextualized worker' do
      let(:worker_class) { ContextualizedDummyWorker }

      it_behaves_like 'it yield'
      it_behaves_like 'log job failure'
      it_behaves_like 'log with context'
      it_behaves_like 'enable model context values', false, nil
    end

    context 'with contextualized model worker' do
      let(:worker_class) { ContextualizedModelDummyWorker }

      it_behaves_like 'it yield'
      it_behaves_like 'log job failure'
      it_behaves_like 'log with context'
      it_behaves_like 'enable model context values', true, { values: ['value']}
    end

    context 'with contextualized model worker' do
      let(:worker_class) { ContextualizedArgsDummyWorker }

      it_behaves_like 'it yield'
      it_behaves_like 'log job failure'
      it_behaves_like 'log with context'
      it_behaves_like 'enable model context values', false, nil

      it 'log with args' do
        job = { 'jid' => 1, 'context' => { request_uuid: 1 }.to_json, 'args' => ['first', 'second'] }
        worker = worker_class.new
        subject.call(worker, job, 'queue') {}
        log = logs.first
        expect(log[:message]).to eq('sidekiq: performing job ContextualizedLogs::ContextualizedArgsDummyWorker: 1, on queue queue')
        expect(log[:job][:id]).to eq(1)
        expect(log[:job][:worker]).to eq('ContextualizedLogs::ContextualizedArgsDummyWorker')
        expect(log[:job][:args]).to eq(first: 'first')
        expect(log[:http][:request_id]).to eq(1)
        log = logs.last
        expect(log[:message]).to eq('sidekiq: completing job ContextualizedLogs::ContextualizedArgsDummyWorker: 1, on queue queue')
        expect(log[:job][:id]).to eq(1)
        expect(log[:job][:worker]).to eq('ContextualizedLogs::ContextualizedArgsDummyWorker')
        expect(log[:job][:args]).to eq(first: 'first')
        expect(log[:http][:request_id]).to eq(1)
      end
    end
  end
end
