# -*- coding: utf-8 -*-

describe "JourneyPatterns", :type => :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        journey_pattern
      end
    end
  end

  let(:referential) { context.referential }
  let(:line) { route.line }
  let(:route) { journey_pattern.route }
  let(:journey_pattern) { context.journey_pattern }

  describe 'show' do
    before(:each) { visit referential_line_route_journey_pattern_path(referential, line, route, journey_pattern) }

    context 'user has permission to create journey patterns' do
      it 'shows the create link for journey pattern' do
        expect(page).to have_content(I18n.t('journey_patterns.actions.new'))
      end
    end

    context 'user does not have permission to create journey patterns' do
      it 'does not show the create link for journey pattern' do
        @user.update_attribute(:permissions, [])
        visit referential_line_route_journey_pattern_path(referential, line, route, journey_pattern)
        expect(page).not_to have_content(I18n.t('journey_patterns.actions.new'))
      end
    end

    context 'user has permission to edit journey patterns' do
      it 'shows the edit link for journey pattern' do
        expect(page).to have_content(I18n.t('journey_patterns.actions.edit'))
      end
    end

    context 'user does not have permission to edit journey patterns' do
      it 'does not show the edit link for journey pattern' do
        @user.update_attribute(:permissions, [])
        visit referential_line_route_journey_pattern_path(referential, line, route, journey_pattern)
        expect(page).not_to have_content(I18n.t('journey_patterns.actions.edit'))
      end
    end

    context 'user has permission to destroy journey patterns' do
      it 'shows the destroy link for journey pattern' do
        expect(page).to have_content(I18n.t('journey_patterns.actions.destroy'))
      end
    end

    context 'user does not have permission to destroy journey patterns' do
      it 'does not show the destroy link for journey pattern' do
        @user.update_attribute(:permissions, [])
        visit referential_line_route_journey_pattern_path(referential, line, route, journey_pattern)
        expect(page).not_to have_content(I18n.t('journey_patterns.actions.destroy'))
      end
    end
  end
end
