# frozen_string_literal: true

RSpec.describe Policy::Strategy::Permission, type: :policy_strategy do
  let(:user_permissions) { nil }
  let(:current_user) { build_stubbed(:user, permissions: user_permissions) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::User) }
  end

  describe '#apply' do
    let(:policy_class) { Class.new(Policy::Base) { include Policy::Strategy::Permission::PolicyConcern } }
    let(:policy) { policy_class.new(resource, context: policy_context) }

    let(:args) { [] }
    subject { strategy.apply(action, *args) }

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

      context 'when the context has permission' do
        let(:user_permissions) { ['dummy_models.update'] }
        it { is_expected.to be_truthy }
      end

      context 'when the context has not permission' do
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
        let(:user_permissions) { ['dummy_models.update'] }
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

        context 'when the context has permission' do
          let(:user_permissions) { ['dummy_models.update'] }
          it { is_expected.to be_truthy }
        end
      end

      context 'when policy class defines exceptions' do
        let(:policy_class) do
          Class.new(Policy::Base) do
            include Policy::Strategy::Permission::PolicyConcern

            permission_exception :update, 'dummier_models.dummier_action'
          end
        end

        it 'registers permission exception' do
          expect(policy_class.permission_exceptions).to eq({ update: 'dummier_models.dummier_action' })
        end

        context 'when the context has permission' do
          let(:user_permissions) { ['dummier_models.dummier_action'] }
          it { is_expected.to be_truthy }
        end
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

      context 'when record class name has modules' do
        # rubocop:disable Style/SingleLineMethods,Rails/ApplicationRecord
        let(:args) { Class.new(ActiveRecord::Base) { def self.name; 'Dummy::Model'; end } }
        # rubocop:enable Style/SingleLineMethods,Rails/ApplicationRecord

        before { expect(Policy::Authorizer::Controller).to receive(:policy_class).with(args).and_return(nil) }

        context 'when the context has permission' do
          let(:user_permissions) { ['dummy_models.create'] }
          it { is_expected.to be_truthy }
        end
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

        context 'when the context has permission' do
          let(:user_permissions) { ['dummy_models.create'] }
          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
