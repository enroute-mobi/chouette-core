
describe "/vehicle_journeys/index", :type => :view do

  let!(:referential) { assign :referential, create(:referential) }
  let!(:line) { assign :line, create(:line) }
  let!(:route) { assign :route, create(:route, line: line) }
  let!(:vehicle_journeys) do
    assign :vehicle_journeys, build_paginated_collection(:vehicle_journey, nil, route: route)
  end

  before :each do
    allow(view).to receive(:link_with_search).and_return("#")
    allow(view).to receive(:collection).and_return(vehicle_journeys)
    allow(view).to receive(:current_referential).and_return(referential)
    allow(view).to receive(:has_feature?).and_return(true)
    controller.request.path_parameters[:referential_id] = referential.id
    render
  end

  context "with an opposite_route" do
    let!(:route) { assign :route, create(:route, :with_opposite, line: line) }

    it "should have an 'oppposite route timetable' button" do
      href = view.referential_line_route_vehicle_journeys_path(referential, line, route.opposite_route)
      oppposite_button_selector = "a[href=\"#{href}\"]"

      expect(view.content_for(:page_header_content)).to have_selector oppposite_button_selector
    end
  end
end
