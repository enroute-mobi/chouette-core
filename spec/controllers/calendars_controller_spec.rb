# frozen_string_literal: true

RSpec.describe CalendarsController, type: :controller do
  login_user permissions: []
  let(:workbench) { create(:workbench, organisation: organisation) }

  describe 'GET index' do
    let(:request) { get :index, params: { workbench_id: workbench.id } }

    it_behaves_like 'checks current_organisation'
  end
end
