# frozen_string_literal: true

RSpec.describe ApiKeysController, type: :controller do
  login_user

  describe "GET index" do
    let(:request) { get :index, params: { workbench_id: current_workbench.id } }

    with_permissions 'api_keys.index' do
      it_behaves_like 'checks current_organisation'
    end

    context 'without permission' do
      it 'avoid access' do
        expect(request).to have_http_status(:forbidden)
      end
    end
  end
end
