
describe "/networks/show", :type => :view do

  let!(:network) do
    network = create(:network)
    assign(:network, network.decorate(context: {
      line_referential: network.line_referential
    }))
  end
  let!(:map) { assign(:map, double(:to_html => '<div id="map"/>'.html_safe)) }
  let!(:line_referential) { assign :line_referential, network.line_referential }

  before(:each) do
    allow(view).to receive(:current_referential).and_return(line_referential)
    allow(view).to receive(:resource).and_return(network)
    allow(view).to receive(:resource_class).and_return(Chouette::Network)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    controller.request.path_parameters[:id] = network.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"
    set_invariant "network.object.id", "909"
    set_invariant "network.object.updated_at", "2018/01/23".to_time
    set_invariant "network.object.name", "Name"

    before(:each){
      render template: "networks/show", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "networks/show" }

    %w(create update destroy).each do |p|
      with_permission "networks.#{p}" do
        it { should match_actions_links_snapshot "networks/show_#{p}" }
      end
    end
  end
end
