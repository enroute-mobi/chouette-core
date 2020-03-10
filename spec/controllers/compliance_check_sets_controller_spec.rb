RSpec.describe ComplianceCheckSetsController, :type => :controller do
  login_user

  let(:organisation){ @user.organisation }
  let(:workgroup) { create :workgroup, owner_id: organisation.id }
  let(:workbench) { create :workbench, organisation: organisation, workgroup: workgroup }
  let(:ccset) { create :compliance_check_set, workbench: workbench }

  context "with workbench as parent" do
    describe "GET index" do
      let(:request){ get :index, params: {workbench_id: workbench.id }}
      it_behaves_like 'checks current_organisation'
    end

    describe "GET executed" do
      let(:request){ get :index, params: {workbench_id: workbench.id, id: ccset.id }}
      it_behaves_like 'checks current_organisation'
    end
  end

  context "with workgroup as parent" do
    before do
      # Workaround to prevent rspec default behaviour where workbench wouldn't be instanciated in that context since it isn't called anywhere, but it is needed since organsiation has many workgroups through workbenches
      workbench.update name: "Workaround"
    end

    describe "GET index" do
      let(:request){ get :index, params: {workgroup_id: workgroup.id }}
      it_behaves_like 'checks current_organisation'
    end

    describe "GET executed" do
      let(:request){ get :index, params: {workgroup_id: workgroup.id, id: ccset.id }}
      it_behaves_like 'checks current_organisation'
    end
  end
end
