describe "StopAreas", :type => :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        3.times { stop_area }
      end
    end
  end

  let(:workbench) { context.workbench }
  let!(:stop_areas) { context.stop_area_referential.stop_areas }
  subject { stop_areas.first }

  describe "index" do
    before(:each) { visit workbench_stop_area_referential_stop_areas_path(workbench) }

    it "displays stop_areas" do
      expect(page).to have_content(stop_areas.first.name)
      expect(page).to have_content(stop_areas.last.name)
    end
  end

  describe "show" do
    it "displays stop_area" do
      visit workbench_stop_area_referential_stop_area_path(workbench, stop_areas.first)
      expect(page).to have_content(stop_areas.first.name)
    end
  end

end
