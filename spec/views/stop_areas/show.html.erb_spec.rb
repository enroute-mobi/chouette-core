
describe 'stop_areas/show', type: :view do

  let!(:stop_area_referential) { assign :stop_area_referential, stop_area.stop_area_referential }
  let!(:stop_area) { assign :stop_area, create(:stop_area).decorate }
  let!(:map) { assign(:map, double(:to_html => '<div id="map"/>'.html_safe)) }

  # it "should display a map with class 'stop_area'" do
  #   render
  #   expect(rendered).to have_selector("#map", :class => 'stop_area')
  # end
end
