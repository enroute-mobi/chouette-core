# coding: utf-8
RSpec.describe StopAreaProviderPolicy, type: :pundit_policy do

  let(:context) do
    Chouette.create do
      stop_area_provider
    end
  end

  let(:record){ context.stop_area_provider }

  #  ---------------
  #  Non Destructive
  #  ---------------

  context 'Non Destructive actions →' do
    permissions :index? do
      it_behaves_like 'always allowed', 'anything'
    end
    permissions :show? do
      it_behaves_like 'always allowed', 'anything'
    end
  end


  #  -----------
  #  Destructive
  #  -----------

  context 'Destructive actions →' do
    permissions :create? do
      it_behaves_like 'permitted policy', 'stop_area_providers.create'
    end
    permissions :edit? do
      it_behaves_like 'permitted policy', 'stop_area_providers.update'
    end
    permissions :new? do
      it_behaves_like 'permitted policy', 'stop_area_providers.create'
    end
    permissions :update? do
      it_behaves_like 'permitted policy', 'stop_area_providers.update'
    end

    context 'Delete →' do

      describe 'With no stop area →' do
        permissions :destroy? do
          it_behaves_like 'permitted policy', 'stop_area_providers.destroy'
        end
      end
    
      describe 'With existing stop areas →' do

        let(:context) do
          Chouette.create do
            stop_area_provider do
              stop_area
            end
          end
        end

        permissions :destroy? do
          it_behaves_like 'permitted policy but unmet condition', 'stop_area_providers.destroy'
        end
      end

    end
  end
end
