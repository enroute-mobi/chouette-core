# -*- coding: utf-8 -*-

describe "JourneyPatterns", :type => :feature do
  login_user

  let!(:line) { route.line }
  let!(:route) { create(:route, referential: referential) }
  let!(:journey_pattern) { create(:journey_pattern, :route => route) }

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

  # describe "from routes page to a journey_pattern page" do
  #   it "display route's journey_patterns" do
  #     visit referential_line_route_path(referential,line,route)
  #     click_link I18n.t('routes.show.journey_patterns')
  #     expect(page).to have_content(journey_pattern.name)
  #   end
  # end

  # describe "from route's page to journey_pattern's page" do
  #   it "display journey_pattern properties" do
  #     visit referential_line_route_path(referential,line,route)
  #     click_link I18n.t('routes.show.journey_patterns')
  #     click_link journey_pattern.name
  #     expect(page).to have_content(journey_pattern.published_name)
  #     expect(page).to have_content(journey_pattern.comment)
  #     expect(page).to have_content(journey_pattern.registration_number)
  #   end
  # end
  #
  # describe "from route's page, create a new journey_pattern" do
  #   it "return to route's page that display new journey_pattern" do
  #     visit referential_line_route_path(referential,line,route)
  #     click_link I18n.t("journey_patterns.actions.new")
  #     fill_in "journey_pattern[name]", :with => "A to B"
  #     fill_in "journey_pattern[comment]", :with => "AB"
  #     click_button(I18n.t('formtastic.create',model: I18n.t('activerecord.models.journey_pattern.one')))
  #     expect(page).to have_content("A to B")
  #   end
  # end
  #
  # describe "from route's page, select a journey_pattern and delete it" do
  #   it "return to route's page without journey_pattern name" do
  #     visit referential_line_route_path(referential,line,route)
  #     click_link I18n.t('routes.show.journey_patterns')
  #     click_link journey_pattern.name
  #     click_link I18n.t('journey_patterns.actions.destroy')
  #     click_link I18n.t('routes.show.journey_patterns')
  #     expect(page).not_to have_content(journey_pattern.name)
  #   end
  # end
end
