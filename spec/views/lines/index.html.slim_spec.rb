
describe "/lines/index", :type => :view do
  let(:deactivated_line){ nil }
  let(:line_referential) { assign :line_referential, create(:line_referential, workgroup: current_workbench.workgroup) }
  let(:current_organisation) { current_user.organisation }
  let(:context) {
     {
       current_organisation: current_organisation,
       line_referential: line_referential
     }
   }
  let(:lines) do
    assign :lines, build_paginated_collection(:line, LineDecorator, line_referential: line_referential, context: context)
  end
  let!(:q) { assign :q, Ransack::Search.new(Chouette::Line) }

  before :each do
    deactivated_line
    allow(view).to receive(:collection).and_return(lines)
    allow(view).to receive(:decorated_collection).and_return(lines)
    allow(view).to receive(:current_referential).and_return(line_referential)
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class).and_return(Chouette::Line)
    controller.request.path_parameters[:line_referential_id] = line_referential.id
    controller.request.path_parameters[:action] = "index"
    render
  end

  describe "action links" do
    set_invariant "line_referential.id", "99"
    set_invariant "line_referential.name", "Name"

    before(:each){
      render template: "lines/index", layout: "layouts/application"
    }

    it { should match_actions_links_snapshot "lines/index" }

    %w(create update destroy).each do |p|
      with_permission "lines.#{p}" do
        it { should match_actions_links_snapshot "lines/index_#{p}" }
      end
    end
  end

  context "links" do
    common_items = ->{
      it { should have_link_for_each_item(lines, "show", -> (line){ view.line_referential_line_path(line_referential, line) }) }
      it { should have_link_for_each_item(lines, "network", -> (line){ view.line_referential_network_path(line_referential, line.network) }) }
      it { should have_link_for_each_item(lines, "company", -> (line){ view.line_referential_company_path(line_referential, line.company) }) }
    }

    common_items.call()
    it { should have_the_right_number_of_links(lines, 4) }

    with_permission "lines.change_status" do
      common_items.call()
      it { should have_the_right_number_of_links(lines, 4) }
    end

    with_permission "lines.destroy" do
      common_items.call()
      it {
        should have_link_for_each_item(lines, "destroy", {
          href: ->(line){ view.line_referential_line_path(line_referential, line)},
          method: :delete
        })
      }
      it { should have_the_right_number_of_links(lines, 5) }
    end
  end
end
