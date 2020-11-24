describe "/networks/index", :type => :view do

  let!(:workbench) { assign :workbench, current_workbench }
  let!(:line_referential) { assign :line_referential, create(:line_referential) }
  let(:line_provider) { build :line_provider, line_referential: line_referential, workbench: workbench }
  let(:context) { { workbench: workbench, line_referential: line_referential } }
  let!(:networks) do
    assign :networks, build_paginated_collection(:network, NetworkDecorator, line_provider: line_provider, context: context)
  end
  let!(:search) { assign :q, Ransack::Search.new(Chouette::Network) }

  before(:each) do
    allow(view).to receive(:collection).and_return(networks)
    allow(view).to receive(:decorated_collection).and_return(networks)
    allow(view).to receive(:current_referential).and_return(line_referential)
    controller.request.path_parameters[:workbench_id] = workbench.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class).and_return(Chouette::Network)
  end

  describe "action links" do
    set_invariant "workbench.id", "99"

    before(:each){
      render template: "networks/index", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "networks/index" }

    %w(create update destroy).each do |p|
      with_permission "networks.#{p}" do
        it { should match_actions_links_snapshot "networks/index_#{p}" }
      end
    end
  end
end
