# frozen_string_literal: true

describe '/route_vehicle_journeys/show', type: :view do
  let(:context) do
    Chouette.create do
      line :first
      referential lines: [ :first ] do
        route { 10.times { vehicle_journey } }
      end
    end
  end

  let!(:workbench) { assign :workbench, context.workbench }
  let!(:referential) { assign :referential, context.referential }
  let!(:line) { assign :line, context.line(:first) }
  let!(:route) { assign :route, context.route }
  let!(:vehicle_journeys) { assign :vehicle_journeys, route.vehicle_journeys.page(1) }

  before :each do
    allow(view).to receive(:link_with_search).and_return('#')
    allow(view).to receive(:collection).and_return(vehicle_journeys)
    allow(view).to receive(:current_organisation).and_return(referential.organisation)
    allow(view).to receive(:current_referential).and_return(referential)
    allow(view).to receive(:has_feature?).and_return(true)
    controller.request.path_parameters[:referential_id] = referential.id
    render
  end

  context "with an opposite_route" do
    let!(:route) { assign :route, create(:route, :with_opposite, line: line) }

    it "should have an 'opposite route timetable' button" do
      href = view.workbench_referential_route_vehicle_journeys_path(
        context.referential.workbench,
        referential,
        route.opposite_route
      )
      oppposite_button_selector = "a[href=\"#{href}\"]"

      expect(view.content_for(:page_header_content)).to have_selector oppposite_button_selector
    end
  end
end
