require 'spec_helper'

describe "/stop_areas/edit", :type => :view do

  let!(:stop_area_referential) { assign :stop_area_referential, stop_area.stop_area_referential }
  let!(:stop_area) { assign(:stop_area, create(:stop_area)) }
  let!(:map) { assign(:map, double(:to_html => '<div id="map"/>'.html_safe)) }

  before do
    allow(view).to receive(:has_feature?)
    allow(view).to receive(:resource){ stop_area }
  end

  describe "form" do
    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_tag "input[type=text][name='stop_area[name]'][value=?]", stop_area.name
      end
    end
  end
end
