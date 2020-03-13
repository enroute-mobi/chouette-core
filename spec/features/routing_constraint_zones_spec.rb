# -*- coding: utf-8 -*-

describe 'RoutingConstraintZones', type: :feature do
  login_user

  let(:referential) { Referential.first }
  let!(:line) { create :line, referential: referential }
  let!(:route) { create :route, line: line }
  let!(:routing_constraint_zones) { Array.new(2) { create :routing_constraint_zone, route: route } }
  let(:routing_constraint_zone) { routing_constraint_zones.first }

  describe 'index' do
    before(:each) { visit referential_line_routing_constraint_zones_path(referential, line) }

    it 'displays referential routing constraint zones' do
      expect(page).to have_content(routing_constraint_zones.first.name)
      expect(page).to have_content(routing_constraint_zones.last.name)
    end

    it 'can search referential routing constraint zones by name' do
      fill_in 'q_name_or_short_id_cont', with: routing_constraint_zones.first.name
      click_button 'Filtrer'

      expect(page).to have_content(routing_constraint_zones.first.name)
      expect(page).not_to have_content(routing_constraint_zones.last.name)
    end

    context 'user has permission to create routing_constraint_zones' do
      it 'shows a create link for routing_constraint_zones' do
        expect(page).to have_content(I18n.t('actions.add'))
      end
    end

    context 'user does not have permission to create routing_constraint_zones' do
      it 'does not show a create link for routing_constraint_zones' do
        @user.update_attribute(:permissions, [])
        visit referential_line_routing_constraint_zones_path(referential, line)
        expect(page).not_to have_content(I18n.t('actions.add'))
      end
    end

    context 'user has permission to edit routing_constraint_zones' do
      it 'shows an edit button for routing_constraint_zones' do
        expect(page).to have_link(I18n.t('actions.edit'), href: edit_referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone))
      end
    end

    context 'user does not have permission to edit routing_constraint_zones' do
      it 'does not show a edit link for routing_constraint_zones' do
        @user.update_attribute(:permissions, [])
        visit referential_line_routing_constraint_zones_path(referential, line)
        expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone))
      end
    end

    context 'user has permission to destroy routing_constraint_zones' do
      it 'shows a destroy link for routing_constraint_zones' do
        expect(page).to have_link(I18n.t('actions.destroy'), href: referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone))
      end
    end

    context 'user does not have permission to destroy routing_constraint_zones' do
      it 'does not show a destroy button for routing_constraint_zones' do
        @user.update_attribute(:permissions, [])
        visit referential_line_routing_constraint_zones_path(referential, line)
        expect(page).not_to have_link(I18n.t('actions.destroy'), href: referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone))
      end
    end
  end

  describe 'show' do
    it 'displays referential routing constraint zone' do
      visit referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone)
      expect(page).to have_content(routing_constraint_zone.name)
    end
  end
end
