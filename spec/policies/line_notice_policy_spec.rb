RSpec.describe Chouette::LineNoticePolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      workbench :second
      workbench :first do
        line_notice
      end
    end
  end

  let(:record) { context.line_notice }

  #  ---------------
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

  #  -----------
  #  Destructive
  #  -----------

  context 'Destructive actions →' do
    context 'record belongs to a line provider on which the user has rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:first)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'line_notices.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'line_notices.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy', 'line_notices.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy', 'line_notices.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy', 'line_notices.destroy'
      end
    end

    context 'record belongs to a line provider on which the user has no rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:second)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'line_notices.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'line_notices.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy but unmet condition', 'line_notices.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy but unmet condition', 'line_notices.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy but unmet condition', 'line_notices.destroy'
      end
    end

  end

end
