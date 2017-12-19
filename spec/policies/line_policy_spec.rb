RSpec.describe LinePolicy, type: :policy do

  let( :record ){ build_stubbed :line }
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
      it_behaves_like 'permitted policy', 'lines.create'
    end
    permissions :destroy? do
      it_behaves_like 'permitted policy', 'lines.destroy'
    end
    permissions :edit? do
      it_behaves_like 'permitted policy', 'lines.update'
    end
    permissions :new? do
      it_behaves_like 'permitted policy', 'lines.create'
    end
    permissions :update? do
      it_behaves_like 'permitted policy', 'lines.update'
    end
  end


  #
  #  Custom Footnote Permissions
  #  ---------------------------

  permissions :create_footnote? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.create', archived: true
  end

  permissions :destroy_footnote? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.destroy', archived: true
  end

  permissions :update_footnote? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.update', archived: true
  end
end
