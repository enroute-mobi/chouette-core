RSpec.describe CompanyPolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      workbench :second
      workbench :first do
        company
      end
    end
  end

  let(:record) { context.company }

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
        it_behaves_like 'permitted policy', 'companies.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'companies.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy', 'companies.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy', 'companies.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy', 'companies.destroy'
      end
    end

    context 'record belongs to a line provider on which the user has no rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:second)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'companies.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'companies.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy but unmet condition', 'companies.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy but unmet condition', 'companies.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy but unmet condition', 'companies.destroy'
      end
    end

  end
end
