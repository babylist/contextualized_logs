require 'rails_helper'
require 'active_record'

module ContextualizedLogs
  RSpec.describe ContextualizedModel do
    class Model < ActiveRecord::Base
      include ContextualizedModel
      contextualizable keys: { values: :value }
    end

    class FakeModel
      def value
        'value'
      end
    end

    describe '.contextualizable' do
      it 'set contextualizable keys' do
        expect(Model.contextualizable_keys).to eq(values: :value)
      end
    end

    describe '.contextualize' do
      subject do
        model = FakeModel.new
        described_class.send(:contextualize, model, Model.contextualizable_keys)
      end
      
      before do
        CurrentContext.model_context_values_enabled = model_context_values_enabled
      end

      context 'with model_context_values_enabled == true' do
        let(:model_context_values_enabled) { true }

        it 'set contextualizable values' do
          subject
          expect(CurrentContext.context_values).to eq(values: ['value'])
        end
      end

      context 'with model_context_values_enabled == false' do
        let(:model_context_values_enabled) { false }

        it 'set contextualizable values' do
          subject
          expect(CurrentContext.context_values).to eq(nil)
        end
      end

    end

    # context 'with model_context_values_enabled' do
    #   before do
    #     CurrentContext.model_context_values_enabled = true
    #   end
    #
    #   describe '.after_find' do
    #     it 'contextualize values' do
    #       model = FakeModel.new
    #       puts Model.__callbacks.inspect
    #       Model.run_callbacks(:after_find)
    #       expect(CurrentContext.context_values).to eq(values: :value)
    #     end
    #   end
    # end
    #
    # context 'when context enabled' do
    #   before do
    #     CurrentContext.model_context_values_enabled = true
    #   end
    #
    #   describe 'find' do
    #     let!(:user) { create(:user) }
    #
    #     it 'contextualize' do
    #       BLRegistry::User.last
    #       expect(CurrentContext.context_values).to eq(user_ids: [user.id])
    #     end
    #   end
    #
    #   describe 'create' do
    #     it 'contextualize' do
    #       user = create(:user)
    #       expect(CurrentContext.context_values).to eq(user_ids: [user.id])
    #     end
    #   end
    # end
    #
    # context 'when context disabled (default)' do
    #   before do
    #     # default
    #     # CurrentContext.context_enabled = true
    #   end
    #
    #   describe 'find' do
    #     let!(:user) { create(:user) }
    #
    #     it 'does NOT contextualize' do
    #       BLRegistry::User.last
    #       expect(CurrentContext.context_values).not_to eq(user_ids: [user.id])
    #     end
    #   end
    #
    #   describe 'create' do
    #     it 'does NOT contextualize' do
    #       user = create(:user)
    #       expect(CurrentContext.context_values).not_to eq(user_ids: [user.id])
    #     end
    #   end
    # end
  end
end
