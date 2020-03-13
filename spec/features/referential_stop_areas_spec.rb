# -*- coding: utf-8 -*-

describe 'ReferentialStopAreas', type: :feature do
  login_user

  let(:referential) { Referential.first }
  let(:stop_area_referential) { referential.stop_area_referential }
  let!(:stop_areas) { Array.new(2) { create :stop_area, stop_area_referential: stop_area_referential } }

  describe 'index' do
    before(:each) { visit stop_area_referential_stop_areas_path(referential.workbench.stop_area_referential) }

    it 'displays referential stop_areas' do
      expect(page).to have_content(stop_areas.first.name)
      expect(page).to have_content(stop_areas.last.name)
    end

    context 'filtering' do
      it 'supports filtering by name' do
        fill_in 'q[name_or_short_id_or_registration_number_cont]', with: stop_areas.first.name
        click_button 'search-btn'
        expect(page).to have_content(stop_areas.first.name)
        expect(page).not_to have_content(stop_areas.last.name)
      end

      it 'supports filtering by objectid' do
        fill_in 'q[name_or_short_id_or_registration_number_cont]', with: stop_areas.first.get_objectid.short_id
        click_button 'search-btn'
        expect(page).to have_content(stop_areas.first.name)
        expect(page).not_to have_content(stop_areas.last.name)
      end
    end
  end

  describe 'show' do
    it 'displays referential stop area' do
      visit stop_area_referential_stop_area_path(stop_areas.first.stop_area_referential, stop_areas.first)
      expect(page).to have_content(stop_areas.first.name)
    end
  end
end
