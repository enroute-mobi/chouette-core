# frozen_string_literal: true

RSpec.describe CalendarsController, type: :controller do
  login_user

  describe 'GET index' do
    let(:request) { get :index, params: { workbench_id: current_workbench.id } }

    it_behaves_like 'checks current_organisation'
  end
end
