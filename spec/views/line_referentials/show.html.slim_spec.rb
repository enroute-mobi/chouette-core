describe "/line_referentials/show", :type => :view do
  let(:context) do
    Chouette.create do
      workgroup owner: Organisation.find_by!(code: 'first') do
        workbench
      end
    end
  end

  let(:workbench) { assign :workbench, context.workbench }
  let(:line_referential) { assign :line_referential, context.line_referential.decorate(context: { workbench: workbench }) }

  before :each do
    controller.request.path_parameters[:workbench_id] = workbench.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
    allow(view).to receive(:resource).and_return(line_referential)
    allow(view).to receive(:resource_class).and_return(line_referential.class)

    render template: "line_referentials/show", layout: "layouts/application"
  end

  it "should not present syncing infos and button" do
    expect(rendered).to_not have_selector("a[href=\"#{view.sync_workbench_line_referential_path(workbench)}\"]")
  end

  with_permission "line_referentials.synchronize" do
    it "should present syncing infos and button" do
      expect(rendered).to have_selector("a[href=\"#{view.sync_workbench_line_referential_path(workbench)}\"]")
    end
  end
end
