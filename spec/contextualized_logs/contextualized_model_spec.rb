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
        expect(Model.contextualizable_keys).to eq(values: :value)
      end
    end

    describe '.contextualize' do
      subject do
        model = FactoryBot.create(:model, value: 'value')
        described_class.send(:contextualize, model, Model.contextualizable_keys, CurrentContext)
      end

      context 'with contextualize_model_enabled == true' do
        let(:contextualize_model_enabled) { true }

        it 'set contextualizable values' do
          subject
          expect(current_context.context_values).to eq(values: ['value'])
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

    RSpec.shared_examples 'after_find context' do |context|
      describe '.after_find' do
        it 'does' do
          model = FactoryBot.create(:model, value: 'a')
          current_context.reset
          current_context.contextualize_model_enabled = contextualize_model_enabled
          Model.find(model.id)
          expect(current_context.context_values).to eq(context)
        end
      end
    end

    RSpec.shared_examples 'after_create context' do |context|
      describe '.after_create' do
        it 'set context' do
          FactoryBot.create(:model, value: 'a')
          expect(current_context.context_values).to eq(context)
        end
      end
    end

    context 'with CurrentContext.contextualize_model_enabled == true' do
      let(:contextualize_model_enabled) { true }

      it_behaves_like 'after_create context', { values: ['a'] }
      it_behaves_like 'after_find context', { values: ['a'] }
    end

    context 'with CurrentContext.contextualize_model_enabled == false' do
      let(:contextualize_model_enabled) { false }

      it_behaves_like 'after_create context', nil
      it_behaves_like 'after_find context', nil
    end
  end
end
