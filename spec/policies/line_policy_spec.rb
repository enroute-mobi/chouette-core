RSpec.describe LinePolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      workbench :second
      workbench :first do
        line
      end
    end
  end

  let(:record) { context.line }

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
        it_behaves_like 'permitted policy', 'lines.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'lines.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy', 'lines.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy', 'lines.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy', 'lines.destroy'
      end
    end

    context 'record belongs to a line provider on which the user has no rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:second)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'lines.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'lines.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy but unmet condition', 'lines.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy but unmet condition', 'lines.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy but unmet condition', 'lines.destroy'
      end
    end

  end

end
