
RSpec.describe MergesController, :type => :controller do
  login_user

  let(:workbench) { create :workbench, organisation: organisation }

  describe "GET available_referentials" do
    let(:request){ get :available_referentials, params: { workbench_id: workbench.id }}
    it_behaves_like 'checks current_organisation'
  end
end
