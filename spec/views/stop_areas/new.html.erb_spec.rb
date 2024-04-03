describe "/stop_areas/new", type: :view do

  let(:context) { Chouette.create { stop_area_referential } }

  let!(:workbench) { assign :workbench, current_workbench }
  let!(:stop_area) { assign :stop_area, context.stop_area_referential.stop_areas.build(name: 'Test') }

  before do
    allow(view).to receive(:has_feature?)
    allow(view).to receive(:resource){ stop_area }
    allow(view).to receive(:resource_class){ stop_area.class }
    allow(view).to receive(:candidate_stop_area_providers) { [] }
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", stop_area.name
      end
    end
  end
end
