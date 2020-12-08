describe "/lines/show", :type => :view do

  let(:context) do
    Chouette.create do
      network :network
      company :company
      line network: :network, company: :company
    end
  end
  let!(:workbench) { assign :workbench, context.workbench }
  let!(:line) do
    assign :line, context.line.decorate(context: {
      workbench: workbench,
      line_referential: context.line_referential,
      current_organisation: workbench.organisation
    })
  end

  before do
    allow(view).to receive_messages(current_organisation: workbench.organisation,
                                    resource: line)
    controller.request.path_parameters[:workbench_id] = workbench.id
    controller.request.path_parameters[:id] = line.id

    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
    allow(view).to receive(:resource_class).and_return(Chouette::Line)
  end

  describe "action links" do
    set_invariant "workbench.id", "99"
    set_invariant "line.object.id", "99"
    set_invariant "line.object.name", "Name"
    set_invariant "line.company.id", "99"
    set_invariant "line.network.id", "99"
    set_invariant "line.updated_at", "2018/01/23".to_time

    before(:each) do
      render template: "lines/show", layout: "layouts/application"
    end

    it { should match_actions_links_snapshot "lines/show" }

    %w(create update destroy).each do |p|
      with_permission "lines.#{p}" do
        it { should match_actions_links_snapshot "lines/show_#{p}" }
      end
    end
  end
end
