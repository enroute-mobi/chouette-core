# -*- coding: utf-8 -*-

describe "StopAreas", :type => :feature do
  login_user

  let(:stop_area_referential) { create :stop_area_referential, member: @user.organisation }
  let!(:stop_areas) { Array.new(2) { create :stop_area, stop_area_referential: stop_area_referential } }
  subject { stop_areas.first }

  describe "index" do
    before(:each) { visit stop_area_referential_stop_areas_path(stop_area_referential) }

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
      visit stop_area_referential_stop_area_path(stop_area_referential, stop_areas.first)
      expect(page).to have_content(stop_areas.first.name)
    end

    # it "display map" do
    #   visit stop_area_referential_stop_areas_path(stop_area_referential)
    #   # click_link "#{stop_areas.first.name}"
    #   visit stop_area_referential_stop_area_path(stop_area_referential, stop_areas.first)
    #   expect(page).to have_selector("#map.stop_area")
    # end

  end

  # Fixme #1780
  # describe "new" do
  #   it "creates stop_area and return to show" do
  #     visit stop_area_referential_stop_areas_path(stop_area_referential)
  #     click_link "Ajouter un arrêt"
  #     fill_in "stop_area_name", :with => "StopArea 1"
  #     fill_in "Numéro d'enregistrement", :with => "test-1"
  #     fill_in "Identifiant Neptune", :with => "test:StopArea:1"
  #     click_button("Créer arrêt")
  #     expect(page).to have_content("StopArea 1")
  #   end
  # end

  # Fixme #1780
  # describe "edit and return to show" do
  #   it "edit stop_area" do
  #     visit stop_area_referential_stop_area_path(stop_area_referential, subject)
  #     click_link "Editer cet arrêt"
  #     fill_in "stop_area_name", :with => "StopArea Modified"
  #     fill_in "Numéro d'enregistrement", :with => "test-1"
  #     click_button("Editer arrêt")
  #     expect(page).to have_content("StopArea Modified")
  #   end
  # end

end
