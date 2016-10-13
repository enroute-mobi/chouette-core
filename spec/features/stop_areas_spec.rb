# -*- coding: utf-8 -*-
require 'spec_helper'

describe "StopAreas", :type => :feature do
  login_user

  let(:stop_area_referential) { create :stop_area_referential }
  let!(:stop_areas) { Array.new(2) { create :stop_area, stop_area_referential: stop_area_referential } }
  subject { stop_areas.first }

  describe "list" do
    it "display stop_areas" do
      visit stop_area_referential_stop_areas_path(stop_area_referential)
      expect(page).to have_content(stop_areas.first.name)
      expect(page).to have_content(stop_areas.last.name)
    end
  end

  describe "show" do
    it "display stop_area" do
      visit stop_area_referential_stop_areas_path(stop_area_referential)
      click_link "#{stop_areas.first.name}"
      expect(page).to have_content(stop_areas.first.name)
    end

    it "display map" do
      visit stop_area_referential_stop_areas_path(stop_area_referential)
      click_link "#{stop_areas.first.name}"
      expect(page).to have_selector("#map.stop_area")
    end

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
  #     click_link "Modifier cet arrêt"
  #     fill_in "stop_area_name", :with => "StopArea Modified"
  #     fill_in "Numéro d'enregistrement", :with => "test-1"
  #     click_button("Modifier arrêt")
  #     expect(page).to have_content("StopArea Modified")
  #   end
  # end

end
