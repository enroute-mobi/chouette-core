
describe "/networks/index", :type => :view do

  let!(:line_referential) { assign :line_referential, create(:line_referential) }
  let(:context){{line_referential: line_referential}}
  let!(:networks) do
    assign :networks, build_paginated_collection(:network, NetworkDecorator, line_referential: line_referential, context: context)
  end

  let!(:search) { assign :q, Ransack::Search.new(Chouette::Network) }

  # it "should render a show link for each group" do
  #   puts networks.inspect
  #   render
  #   networks.each do |network|
  #     expect(rendered).to have_selector("a[href='#{view.line_referential_network_path(line_referential, network)}']")
  #   end
  # end
  #
  # it "should render a link to create a new group" do
  #   render
  #   expect(view.content_for(:sidebar)).to have_selector("a[href='#{new_line_referential_network_path(line_referential)}']")
  # end
  before(:each) do
    allow(view).to receive(:collection).and_return(networks)
    allow(view).to receive(:decorated_collection).and_return(networks)
    allow(view).to receive(:current_referential).and_return(line_referential)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class).and_return(Chouette::Network)
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"

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
