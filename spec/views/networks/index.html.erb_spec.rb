describe "/networks/index", :type => :view do
  let(:context) do
    Chouette.create do
      workbench :second
      workbench :first do
        network :first
        network :second
      end
    end
  end

  let(:policy_context_class) { Policy::Context::Workbench }
  let(:workbench) { assign :workbench, context.workbench(:first) }
  let(:line_provider) { context.network(:first).line_provider }
  let(:line_referential) { assign :line_referential, line_provider.line_referential }
  let(:decorator_context) {
    {
      current_organisation: current_user.organisation,
      line_referential: line_referential,
      workbench: workbench
    }
  }

  let(:networks) do
    assign :networks, paginate_collection(Chouette::Network, NetworkDecorator, 1, decorator_context)
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
