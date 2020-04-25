# https://github.com/mperham/sidekiq/wiki/Middleware
require 'rails_helper'
require 'sidekiq/testing'

module ContextualizedLogs
  RSpec.describe Sidekiq::Middleware::Client::InjectCurrentContext do
    class DummyWorker
      include ::Sidekiq::Worker

      def perform
      end
    end

    class ContextualizedDummyWorker < DummyWorker
      include ContextualizedWorker
      contextualize_worker true
    end

    class ContextualizedModelDummyWorker < DummyWorker
      include ContextualizedWorker
      contextualize_worker true
      contextualize_model true
    end

    subject { described_class.new }
    let(:current_context) { CurrentContext }

    before do
      current_context.request_uuid = 1
    end

    RSpec.shared_examples 'it client yield' do
      it do
        yielded = false
        subject.call(worker_class, {}, '', nil) do
          yielded = true
        end
        expect(yielded).to eq(true)
      end
    end

    describe 'ContextualizedWorker' do
      let!(:model) { FactoryBot.create(:model, value: 'value') }

      context 'with uncontextualized worker' do
        let(:worker_class) { DummyWorker }

        it_behaves_like 'it client yield'

        it 'DOES NOT change job context' do
          job = {'jid' => 1}
          subject.call(worker_class, job, '', nil) do
            expect(job).to eq('jid' => 1)
          end
        end

        it 'DOES NOT log job enqueued' do
          expect(Rails.logger).not_to receive(:info).with("sidekiq: enqueing job #{worker_class}: 1, on queue: ")
          subject.call(worker_class, { 'jid' => 1 }, '', nil) {}
        end

        it 'DOES NOT enable model context values' do
          subject.call(worker_class, { 'jid' => 1 }, '', nil) do
            Model.find(model.id)
          end
          expect(current_context.context_values).to eq(nil)
        end
      end

      context 'with contextualized worker' do
        let(:worker_class) { ContextualizedModelDummyWorker }

        it_behaves_like 'it client yield'

        it 'DOES change job context' do
          job = { 'jid' => 1 }
          subject.call(worker_class, job, '', nil) do
            expect(job['jid']).to eq(1)
            context = JSON.parse(job['context'])
            expect(context['request_uuid']).to eq(1)
            expect(context['enqueued_jobs_ids']).to eq([1])
          end
        end

        it 'DOES log job enqueued' do
          expect(Rails.logger).to receive(:info).with("sidekiq: enqueing job #{worker_class}: 1, on queue: ")
          subject.call(worker_class, { 'jid' => 1 }, '', nil) {}
        end

        context 'with contextualized model' do
          let(:worker_class) { ContextualizedModelDummyWorker }

          it 'DOES enable model context values' do
            subject.call(worker_class, { 'jid' => 1 }, '', nil) do
              Model.find(model.id)
            end
            expect(current_context.context_values).to eq(model_values: ['value'], model_ids: [model.id])
          end
        end
      end
    end
  end
end
