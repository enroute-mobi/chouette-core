describe "/stop_area_referentials/show", :type => :view do
  let(:context) do
    Chouette.create do
      workgroup owner: Organisation.find_by!(code: 'first') do
        workbench
      end
    end
  end

  let(:workbench) { assign :workbench, context.workbench }
  let(:stop_area_referential) { assign :stop_area_referential, context.stop_area_referential.decorate(context: { workbench: workbench }) }
  let!(:connection_links) { assign :connection_links, [] }

  before :each do
    controller.request.path_parameters[:workbench_id] = workbench.id
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :show))
    allow(view).to receive(:resource).and_return(stop_area_referential)
    allow(view).to receive(:resource_class).and_return(stop_area_referential.class)
    render template: "stop_area_referentials/show", layout: "layouts/application"
  end

  let(:link_to_sync) { "a[href=\"#{view.sync_workbench_stop_area_referential_path(workbench)}\"]" }

  it "should not present syncing infos and button" do
    expect(rendered).to_not have_selector(link_to_sync)
  end

  with_permission "stop_area_referentials.synchronize" do
    it "should present syncing infos and button" do
      expect(rendered).to have_selector(link_to_sync, count: 1)
    end
  end
end
