# frozen_string_literal: true

RSpec.describe Policy::Strategy::Permission, type: :policy_strategy do
  let(:user_permissions) { nil }
  let(:current_user) { build_stubbed(:user, permissions: user_permissions) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::User) }
  end

  describe '#apply' do
    let(:args) { [] }
    subject { strategy.apply(action, *args) }

    context ':update' do
      # rubocop:disable Style/SingleLineMethods
      let(:policy_class) { Class.new(Policy::Base) { def self.name; 'DummyPolicy'; end } }
      # rubocop:enable Style/SingleLineMethods
      let(:policy) { policy_class.new(resource, context: policy_context) }
      let(:action) { :update }

      context 'when the context has permission' do
        let(:user_permissions) { ['dummy_policies.update'] }
        it { is_expected.to be_truthy }
      end

      context 'when the context has not permission' do
        it { is_expected.to be_falsy }
      end
    end

    context ':create' do
      let(:action) { :create }
      # rubocop:disable Style/SingleLineMethods,Rails/ApplicationRecord
      let(:args) { Class.new(ActiveRecord::Base) { def self.name; 'DummyModel'; end } }
      # rubocop:enable Style/SingleLineMethods,Rails/ApplicationRecord

      context 'when the context has permission' do
        let(:user_permissions) { ['dummy_models.create'] }
        it { is_expected.to be_truthy }
      end

      context 'when the context has not permission' do
        it { is_expected.to be_falsy }
      end
    end
  end
end
