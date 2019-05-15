RSpec.describe Chouette::LineNoticePolicy, type: :policy do

  let( :record ){ build_stubbed :line_notice }
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
      it_behaves_like 'permitted policy', 'line_notices.create'
    end
    permissions :destroy? do
      it_behaves_like 'permitted policy', 'line_notices.destroy'
    end
    permissions :edit? do
      it_behaves_like 'permitted policy', 'line_notices.update'
    end
    permissions :new? do
      it_behaves_like 'permitted policy', 'line_notices.create'
    end
    permissions :update? do
      it_behaves_like 'permitted policy', 'line_notices.update'
    end
  end
end
