require 'rails_helper'

module ContextualizedLogs
  RSpec.describe ContextualizedModel do
    let(:current_context) { CurrentContext }
    let(:contextualize_model_enabled) { true }

    before do
      current_context.contextualize_model_enabled = contextualize_model_enabled
    end

    describe '.contextualizable' do
      it 'set contextualizable keys' do
        expect(Model.contextualizable_keys).to eq(model_values: :value, model_ids: :id)
      end
    end

    describe '.contextualize' do
      let(:model) { FactoryBot.create(:model, value: 'value') }
      subject do
        described_class.send(:contextualize, model, Model.contextualizable_keys, CurrentContext)
      end

      context 'with contextualize_model_enabled == true' do
        let(:contextualize_model_enabled) { true }

        it 'set contextualizable values' do
          subject
          expect(current_context.context_values).to eq(model_values: ['value'], model_ids: [model.id])
        end
      end

      context 'with contextualize_model_enabled == false' do
        let(:contextualize_model_enabled) { false }

        it 'set contextualizable values' do
          subject
          expect(current_context.context_values).to eq(nil)
        end
      end

    end

    RSpec.shared_examples 'after_find context' do |expect_context_values|
      describe '.after_find' do
        it 'does' do
          model = FactoryBot.create(:model, value: 'a')
          current_context.reset
          current_context.contextualize_model_enabled = contextualize_model_enabled
          Model.find(model.id)
          if expect_context_values
            expect(current_context.context_values).to eq(model_values: [model.value], model_ids: [model.id])
          else
            expect(current_context.context_values).to eq(nil)
          end
        end
      end
    end

    RSpec.shared_examples 'after_create context' do |expect_context_values|
      describe '.after_create' do
        it 'set context' do
          model = FactoryBot.create(:model, value: 'a')
          if expect_context_values
            expect(current_context.context_values).to eq(model_values: [model.value], model_ids: [model.id])
          else
            expect(current_context.context_values).to eq(nil)
          end
        end
      end
    end

    context 'with CurrentContext.contextualize_model_enabled == true' do
      let(:contextualize_model_enabled) { true }

      it_behaves_like 'after_create context', true
      it_behaves_like 'after_find context', true
    end

    context 'with CurrentContext.contextualize_model_enabled == false' do
      let(:contextualize_model_enabled) { false }

      it_behaves_like 'after_create context', false
      it_behaves_like 'after_find context', false
    end
  end
end
