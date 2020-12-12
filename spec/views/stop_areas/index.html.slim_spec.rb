describe "/stop_areas/index", :type => :view do
  let!(:workbench) { assign :workbench, current_workbench }
  let(:stop_area_provider) { build :stop_area_provider, stop_area_referential: stop_area_referential, workbench: workbench }
  let(:deactivated_stop_area){ nil }
  let(:stop_area_referential) { assign :stop_area_referential, create(:stop_area_referential) }
  let(:stop_areas) do
    assign :stop_areas, build_paginated_collection(:stop_area, StopAreaDecorator, stop_area_provider: stop_area_provider, context: context)
  end
  let(:context) { { workbench: workbench } }
  let!(:q) { assign :q, Ransack::Search.new(Chouette::StopArea) }

  before :each do
    deactivated_stop_area
    allow(view).to receive(:link_with_search).and_return("#")
    allow(view).to receive(:collection).and_return(stop_areas)
    allow(view).to receive(:current_referential).and_return(stop_area_referential)
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:resource_class){ stop_area.class }
    controller.request.path_parameters[:workbench_id] = workbench.id
    render
  end

  common_items = ->{
    # See CHOUETTE-714
    xit { should have_link_for_each_item(stop_areas, "show", -> (stop_area){ view.workbench_stop_area_referential_stop_area_path(workbench, stop_area) }) }
  }

  common_items.call()
  it { should have_the_right_number_of_links(stop_areas, 1) }

  with_permission "stop_areas.create" do
    common_items.call()
    it { should_not have_link_for_each_item(stop_areas, "create", -> (stop_area){ view.new_workbench_stop_area_referential_stop_area_path(workbench) }) }
    it { should have_the_right_number_of_links(stop_areas, 1) }
  end

  with_permission "stop_areas.update" do
    common_items.call()
    # See CHOUETTE-714
    xit { should have_link_for_each_item(stop_areas, "edit", -> (stop_area){ view.edit_workbench_stop_area_referential_stop_area_path(workbench, stop_area) }) }
    it { should have_the_right_number_of_links(stop_areas, 2) }
  end

  with_permission "stop_areas.change_status" do
    common_items.call()
    it { should have_the_right_number_of_links(stop_areas, 1) }
  end

  with_permission "stop_areas.destroy" do
    common_items.call()
    # See CHOUETTE-714
    xit {
      should have_link_for_each_item(stop_areas, "destroy", {
        href: ->(stop_area){ view.stop_area_referential_stop_area_path(stop_area_referential, stop_area)},
        method: :delete
      })
    }
    it { should have_the_right_number_of_links(stop_areas, 2) }
  end

end
