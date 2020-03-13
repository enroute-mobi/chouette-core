
RSpec.describe WorkbenchOutputsController, :type => :controller do
  login_user

  let(:workbench) { create :workbench, organisation: organisation }

  describe "GET show" do
    let(:request){ get :show, params: { workbench_id: workbench.id }}
    it_behaves_like 'checks current_organisation'
  end
end
