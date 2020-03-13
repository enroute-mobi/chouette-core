
describe "/lines/show", :type => :view do

  assign_referential
  let!(:line) do
    line = create(:line)
    assign :line, line.decorate(context: {
      line_referential: line.line_referential,
      current_organisation: referential.organisation
    })
  end
  let!(:line_referential) { assign :line_referential, line.line_referential }
  let!(:routes) { assign :routes, Array.new(2) { create(:route, :line => line) }.paginate }
  let!(:map) { assign(:map, double(:to_html => '<div id="map"/>'.html_safe)) }

  before do
    allow(view).to receive_messages(current_organisation: referential.organisation, resource: line)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    controller.request.path_parameters[:id] = line.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
    allow(view).to receive(:resource_class).and_return(Chouette::Line)
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"
    set_invariant "line.object.id", "99"
    set_invariant "line.object.name", "Name"
    set_invariant "line.company.id", "99"
    set_invariant "line.network.id", "99"
    set_invariant "line.updated_at", "2018/01/23".to_time

    before(:each){
      render template: "lines/show", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "lines/show" }

    %w(create update destroy).each do |p|
      with_permission "lines.#{p}" do
        it { should match_actions_links_snapshot "lines/show_#{p}" }
      end
    end
  end
end
