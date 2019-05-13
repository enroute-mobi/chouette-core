RSpec.describe ConnectionLinkPolicy, type: :policy do

  let( :record ){ build_stubbed :connection_link }
  before { stub_policy_scope(record) }

  #
  #  Non Destructive
  #  ---------------

  context 'Non Destructive actions →' do
    permissions :index? do
      it_behaves_like 'always allowed', 'anything', archived_and_finalised: true
    end
    permissions :show? do
      it_behaves_like 'always allowed', 'anything', archived_and_finalised: true
    end
  end


  #
  #  Destructive
  #  -----------

  context 'Destructive actions →' do
    permissions :create? do
      it_behaves_like 'permitted policy', 'connection_links.create'
    end
    permissions :destroy? do
      it_behaves_like 'permitted policy', 'connection_links.destroy'
    end
    permissions :edit? do
      it_behaves_like 'permitted policy', 'connection_links.update'
    end
    permissions :new? do
      it_behaves_like 'permitted policy', 'connection_links.create'
    end
    permissions :update? do
      it_behaves_like 'permitted policy', 'connection_links.update'
    end
  end
end
