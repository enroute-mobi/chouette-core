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

    context 'filtering' do
      it 'supports filtering by name' do
        fill_in 'q[name_or_short_id_or_registration_number_cont]',
          with: stop_areas.first.name
        click_button 'search-btn'
        expect(page).to have_content(stop_areas.first.name)
        expect(page).not_to have_content(stop_areas.last.name)
      end

      it 'supports filtering by objectid' do
        fill_in 'q[name_or_short_id_or_registration_number_cont]',
          with: stop_areas.first.get_objectid.short_id
        click_button 'search-btn'
        expect(page).to have_content(stop_areas.first.name)
        expect(page).not_to have_content(stop_areas.last.name)
      end

      context 'filtering by status' do
        before(:each) do
          stop_areas.first.activate!
          stop_areas.last.activate!
          stop_areas.last.deactivate!
        end

        describe 'updated stop areas in before block' do

          it 'supports displaying only stop areas in creation' do
            find("#q_by_status_in_creation").set(true)
            click_button 'search-btn'
            expect(page).not_to have_content(stop_areas.first.name)
            expect(page).not_to have_content(stop_areas.last.name)
          end

          it 'supports displaying only confirmed stop areas' do
            find("#q_by_status_confirmed").set(true)
            click_button 'search-btn'
            expect(page).to have_content(stop_areas.first.name)
            expect(page).not_to have_content(stop_areas.last.name)
          end

          it 'supports displaying only deactivated stop areas' do
            find("#q_by_status_deactivated").set(true)
            click_button 'search-btn'
            expect(page).not_to have_content(stop_areas.first.name)
            expect(page).to have_content(stop_areas.last.name)
          end

          it 'should display all stop areas if all filters are checked' do
            find("#q_by_status_in_creation").set(true)
            find("#q_by_status_confirmed").set(true)
            find("#q_by_status_deactivated").set(true)
            click_button 'search-btn'
            expect(page).to have_content(stop_areas.first.name)
            expect(page).to have_content(stop_areas.last.name)
          end
        end
      end
    end
  end

  describe "show" do
    it "displays stop_area" do
      visit workbench_stop_area_referential_stop_area_path(workbench, stop_areas.first)
      expect(page).to have_content(stop_areas.first.name)
    end
  end

end
