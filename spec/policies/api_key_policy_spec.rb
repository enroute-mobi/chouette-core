RSpec.describe ApiKeyPolicy do

  let( :record ){ build_stubbed :api_key }
  before { stub_policy_scope(record) }

  subject { described_class }

  permissions :index? do
    it_behaves_like 'always allowed'
  end

  permissions :show? do
    it_behaves_like 'always allowed'
  end

  permissions :create? do
    it_behaves_like 'permitted policy and same organisation', 'api_keys.create'
  end

  permissions :update? do
    it_behaves_like 'permitted policy and same organisation', 'api_keys.update'
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'api_keys.destroy'
  end
end
