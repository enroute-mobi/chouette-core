# frozen_string_literal: true

RSpec.describe WorkbenchOutputsController, type: :controller do
  login_user

  describe 'GET show' do
    let(:request) { get :show, params: { workbench_id: current_workbench.id } }
    it_behaves_like 'checks current_organisation'
  end
end
