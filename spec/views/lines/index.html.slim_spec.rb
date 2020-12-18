describe "/lines/index", :type => :view do

  let(:context) do
    Chouette.create do
      workbench :second
      workbench :first do
        network :first_network
        company :first_company
        line :first, network: :first_network, company: :first_company
        line :second, network: :first_network, company: :first_company
      end
    end
  end

  let(:workbench) { assign :workbench, context.workbench(:first) }
  let(:line_provider) { context.line(:first).line_provider }
  let(:line_referential) { assign :line_referential, line_provider.line_referential }
  let(:network) { context.network(:first_network) }
  let(:company) { context.company(:first_company) }
  let(:decorator_context) {
    {
      current_organisation: current_user.organisation,
      line_referential: line_referential,
      workbench: workbench
    }
  }
  let(:lines) do
    assign :lines, paginate_collection(Chouette::Line, LineDecorator, 1, decorator_context)
  end
  let!(:q) { assign :q, Ransack::Search.new(Chouette::Line) }

  before :each do
    allow(view).to receive(:collection).and_return(lines)
    allow(view).to receive(:decorated_collection).and_return(lines)
    allow(view).to receive(:current_referential).and_return(line_referential)
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class).and_return(Chouette::Line)
    controller.request.path_parameters[:workbench_id] = workbench.id
    controller.request.path_parameters[:action] = "index"
    render
  end

  describe "action links" do
    set_invariant "workbench.id", "99"
    set_invariant "line_referential.name", "Line Referential"

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
      it { should have_link_for_each_item(lines, "show", -> (line){ view.workbench_line_referential_line_path(workbench, line) }) }
      xit { should have_link_for_each_item(lines, "network", -> (line){ view.workbench_line_referential_network_path(line_referential, line.network) }) }
      xit { should have_link_for_each_item(lines, "company", -> (line){ view.workbench_line_referential_company_path(line_referential, line.company) }) }
    }

    common_items.call()
    it { should have_the_right_number_of_links(lines, 4) }

    with_permission "lines.change_status" do
      common_items.call()
      it { should have_the_right_number_of_links(lines, 4) }
    end

    context 'record belongs to a stop area provider on which the user has rights →' do
      let(:pundit_user){ UserContext.new(current_user, referential: current_referential, workbench: workbench)}

      with_permission "lines.destroy" do
        common_items.call()
        it {
          should have_link_for_each_item(lines, "destroy", {
            href: ->(line){ view.workbench_line_referential_line_path(workbench, line)},
            method: :delete
            })
        }
        it { should have_the_right_number_of_links(lines, 5) }
      end
    end

    context 'record belongs to a stop area provider on which the user has no rights →' do
      let(:pundit_user){ UserContext.new(current_user, referential: current_referential, workbench: context.workbench(:second))}

      with_permission "lines.destroy" do
        common_items.call()
        it {
          should_not have_link_for_each_item(lines, "destroy", {
            href: ->(line){ view.workbench_line_referential_line_path(workbench, line)},
            method: :delete
            })
        }
        it { should have_the_right_number_of_links(lines, 4) }
      end
    end
  end

end
