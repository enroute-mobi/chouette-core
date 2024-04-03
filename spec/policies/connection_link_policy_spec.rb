RSpec.describe ConnectionLinkPolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      workbench :first do
        stop_area :first
        stop_area :second
      end
      workbench :second
    end
  end

  let(:record) { create :connection_link, stop_area_provider: context.stop_area(:first).stop_area_provider, departure: context.stop_area(:first), arrival: context.stop_area(:second) }

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

    context 'record belongs to a stop area provider on which the user has rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:first)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'connection_links.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'connection_links.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy', 'connection_links.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy', 'connection_links.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy', 'connection_links.destroy'
      end
    end

    context 'record belongs to a stop area provider on which the user no rights →' do
      before do
        user_context.context[:workbench] =  context.workbench(:second)
      end

      permissions :new? do
        it_behaves_like 'permitted policy', 'connection_links.create'
      end
      permissions :create? do
        it_behaves_like 'permitted policy', 'connection_links.create'
      end
      permissions :edit? do
        it_behaves_like 'permitted policy but unmet condition', 'connection_links.update'
      end
      permissions :update? do
        it_behaves_like 'permitted policy but unmet condition', 'connection_links.update'
      end
      permissions :destroy? do
        it_behaves_like 'permitted policy but unmet condition', 'connection_links.destroy'
      end
    end
  end
end
