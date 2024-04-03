RSpec.describe ApiKeyPolicy, type: :pundit_policy do
  let(:workbench) { create :workbench }
  let(:record) { build_stubbed :api_key, workbench: workbench }
  before { stub_policy_scope(record) }

  subject { described_class }

  permissions :index? do
    it_behaves_like 'always allowed'
  end

  permissions :show? do
    it_behaves_like 'always allowed'
  end

  permissions :create? do
    context 'permission absent → ' do
      it "denies a user without organisation" do
        expect_it.not_to permit(user_context, record)
      end
    end
    context 'permission present → '  do
      it 'allows a user with a different organisation' do
        add_permissions('api_keys.create', to_user: user)
        expect_it.to permit(user_context, record)
      end
    end
  end

  permissions :update? do
    context 'permission absent → ' do
      it "denies a user with a different organisation" do
        expect_it.not_to permit(user_context, record)
      end
      it 'and also a user with the same organisation' do
        user.organisation_id = record.workbench.organisation_id
        expect_it.not_to permit(user_context, record)
      end
    end

    context 'permission present → '  do
      before do
        add_permissions('api_keys.update', to_user: user)
      end

      it 'denies a user with a different organisation' do
        expect_it.not_to permit(user_context, record)
      end

      it 'but allows it for a user with the same organisation' do
        user.organisation_id = record.workbench.organisation_id
        expect_it.to permit(user_context, record)
      end
    end
  end

  permissions :destroy? do
    context 'permission absent → ' do
      it "denies a user with a different organisation" do
        expect_it.not_to permit(user_context, record)
      end
      it 'and also a user with the same organisation' do
        user.organisation_id = record.workbench.organisation_id
        expect_it.not_to permit(user_context, record)
      end
    end

    context 'permission present → '  do
      before do
        add_permissions('api_keys.destroy', to_user: user)
      end

      it 'denies a user with a different organisation' do
        expect_it.not_to permit(user_context, record)
      end

      it 'but allows it for a user with the same organisation' do
        user.organisation_id = record.workbench.organisation_id
        expect_it.to permit(user_context, record)
      end
    end
  end
end
