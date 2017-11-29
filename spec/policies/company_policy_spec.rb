RSpec.describe CompanyPolicy, type: :policy do

  let( :record ){ build_stubbed :company }
  before { stub_policy_scope(record) }


  #
  #  Non Destructive
  #  ---------------

  context 'Non Destructive actions →' do
    permissions :index? do
      it_behaves_like 'always allowed', 'anything', archived: true
    end
    permissions :show? do
      it_behaves_like 'always allowed', 'anything', archived: true
    end
  end


  #
  #  Destructive
  #  -----------

  context 'Destructive actions →' do
    permissions :create? do
      it_behaves_like 'permitted policy and same organisation', 'companies.create', archived: true
    end
    permissions :destroy? do
      it_behaves_like 'permitted policy and same organisation', 'companies.destroy', archived: true
    end
    permissions :edit? do
      it_behaves_like 'permitted policy and same organisation', 'companies.update', archived: true
    end
    permissions :new? do
      it_behaves_like 'permitted policy and same organisation', 'companies.create', archived: true
    end
    permissions :update? do
      it_behaves_like 'permitted policy and same organisation', 'companies.update', archived: true
    end
  end
end
