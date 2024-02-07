RSpec.describe GroupOfLinePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :group_of_line }
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
      it_behaves_like 'always forbidden', 'group_of_lines.create', archived_and_finalised: true
    end
    permissions :destroy? do
      it_behaves_like 'always forbidden', 'group_of_lines.destroy', archived_and_finalised: true
    end
    permissions :edit? do
      it_behaves_like 'always forbidden', 'group_of_lines.update', archived_and_finalised: true
    end
    permissions :new? do
      it_behaves_like 'always forbidden', 'group_of_lines.create', archived_and_finalised: true
    end
    permissions :update? do
      it_behaves_like 'always forbidden', 'group_of_lines.update', archived_and_finalised: true
    end
  end
end
