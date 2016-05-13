require 'spec_helper'

describe "/stop_areas/new", :type => :view do

  let!(:stop_area_referential) { assign :stop_area_referential, stop_area.stop_area_referential }
  let!(:stop_area) { assign(:stop_area, build(:stop_area)) }

  describe "form" do

    it "should render input for name" do
      render
      expect(rendered).to have_selector("form") do
        with_selector "input[type=text][name=?]", stop_area.name
      end
    end

  end
end
