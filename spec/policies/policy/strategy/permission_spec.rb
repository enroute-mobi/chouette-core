# frozen_string_literal: true

RSpec.describe Policy::Strategy::Permission, type: :policy_strategy do
  let(:policy_class) { Class.new(Policy::Base) { include Policy::Strategy::Permission::PolicyConcern } }
  let(:policy_context) { double(:policy_context) }
  let(:policy) { policy_class.new(resource, context: policy_context) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::HasPermission) }
  end

  describe '#apply' do
    let(:args) { [] }
    subject { strategy.apply(action, *args) }

    let(:expected_permission_result) { true }

    before do
      if expected_permission
        expect(policy_context).to receive(:permission?).with(expected_permission).and_return(expected_permission_result)
      end
    end

    context ':update' do
      let(:policy_class) do
        Class.new(Policy::Base) do
          def self.name
            'Policy::DummyModel'
          end

          include Policy::Strategy::Permission::PolicyConcern
        end
      end
      let(:action) { :update }
      let(:expected_permission) { 'dummy_models.update' }

      context 'when the context has permission' do
        it { is_expected.to be_truthy }
      end

      context 'when the context has not permission' do
        let(:expected_permission_result) { false }
        it { is_expected.to be_falsy }
      end

      context 'when policy class name has modules' do
        let(:policy_class) do
          Class.new(Policy::Base) do
            def self.name
              'Policy::Dummy::Model'
            end

            include Policy::Strategy::Permission::PolicyConcern
          end
        end

        it { is_expected.to be_truthy }
      end

      context 'when policy class redefines .permission_namespace' do
        let(:policy_class) do
          Class.new(Policy::Base) do
            include Policy::Strategy::Permission::PolicyConcern

            def self.permission_namespace
              'dummy_models'
            end
          end
        end

        it { is_expected.to be_truthy }
      end

      context 'when policy class defines exceptions' do
        let(:policy_class) do
          Class.new(Policy::Base) do
            include Policy::Strategy::Permission::PolicyConcern

            permission_exception :update, 'dummier_models.dummier_action'
          end
        end
        let(:expected_permission) { 'dummier_models.dummier_action' }

        it { is_expected.to be_truthy }
      end
    end

    context ':create' do
      let(:action) { :create }
      # rubocop:disable Style/SingleLineMethods,Rails/ApplicationRecord
      let(:args) { Class.new(ActiveRecord::Base) { def self.name; 'DummyModel'; end } }
      # rubocop:enable Style/SingleLineMethods,Rails/ApplicationRecord
      let(:expected_permission) { 'dummy_models.create' }

      context 'when the context has permission' do
        it { is_expected.to be_truthy }
      end

      context 'when the context has not permission' do
        let(:expected_permission_result) { false }
        it { is_expected.to be_falsy }
      end

      context 'when record class name has modules' do
        # rubocop:disable Rails/ApplicationRecord
        let(:args) do
          Class.new(ActiveRecord::Base) do
            def self.name
              'Dummy::Model'
            end

            # redefinition since Dummy module does not exist
            def self.model_name
              ActiveModel::Name.new(self)
            end
          end
        end
        # rubocop:enable Rails/ApplicationRecord

        before { expect(Policy::Authorizer::Controller).to receive(:policy_class).with(args).and_return(nil) }

        it { is_expected.to be_truthy }
      end

      context 'when record policy class redefines .permission_namespace' do
        # rubocop:disable Style/SingleLineMethods,Rails/ApplicationRecord
        let(:args) { Class.new(ActiveRecord::Base) { def self.name; 'WrongName'; end } }
        # rubocop:enable Style/SingleLineMethods,Rails/ApplicationRecord
        let(:policy_class) do
          Class.new(Policy::Base) do
            include Policy::Strategy::Permission::PolicyConcern

            def self.permission_namespace
              'dummy_models'
            end
          end
        end

        before { expect(Policy::Authorizer::Controller).to receive(:policy_class).with(args).and_return(policy_class) }

        let(:expected_permission) { 'dummy_models.create' }
      end
    end
  end

  describe 'Policy.permission_exceptions' do
    subject { policy_class.permission_exceptions }

    it { is_expected.to eq({}) }

    context 'when policy class defines exceptions' do
      let(:policy_class) do
        Class.new(Policy::Base) do
          include Policy::Strategy::Permission::PolicyConcern

          permission_exception :update, 'dummier_models.dummier_action'
        end
      end

      it { is_expected.to eq({ update: 'dummier_models.dummier_action' }) }
    end
  end
end
