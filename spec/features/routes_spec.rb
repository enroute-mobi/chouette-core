describe "Routes", :type => :feature do
  let(:context) do
    Chouette.create do
      line :first

      referential lines: [:first] do
        2.times do
          route(line: :first) { journey_pattern }
        end
      end
    end
  end

  let(:user) { @user }
  let(:referential) { context.referential }
  let(:line) { context.line(:first) }
  let(:routes) { context.routes }
  let(:route) { routes.first }
  let(:journey_pattern) { route.journey_patterns.first }

  before { login_user organisation: referential.organisation }

  with_permissions "boiv:read" do
    it "line page displays line's routes" do
      visit referential_line_path(referential, line)
      routes.each do |route|
        expect(page).to have_content(route.name)
      end
    end

    describe "from line's page to route's page" do
      it "display route properties" do
        visit referential_line_path(referential, line)
        click_link "#{route.name}"
        expect(page).to have_content(route.name)
        expect(page).to have_content(route.number)
      end
    end

    describe 'show' do
      before(:each) { visit referential_line_route_path(referential, line, route) }

      context 'user has permission to edit journey patterns' do
        skip "not sure the spec is correct or the code" do
          it 'shows edit links for journey patterns' do
            expect(page).to have_link(I18n.t('actions.edit'), href: edit_referential_line_route_journey_pattern_path(referential, line, route, journey_pattern))
          end
        end
      end

      context 'user does not have permission to edit journey patterns' do
        it 'does not show edit links for journey patterns' do
          user.update_attribute(:permissions, [])
          visit referential_line_route_path(referential, line, route)
          expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_line_route_journey_pattern_path(referential, line, route, journey_pattern))
        end
      end

      context 'user has permission to destroy journey patterns' do
        it 'shows destroy links for journey patterns' do
          expect(page).to have_content(I18n.t('actions.destroy'))
        end
      end

      context 'user does not have permission to destroy journey patterns' do
        it 'does not show destroy links for journey patterns' do
          user.update_attribute(:permissions, [])
          visit referential_line_route_path(referential, line, route)
          expect(page).not_to have_link(I18n.t('actions.destroy'), href: referential_line_route_journey_pattern_path(referential, line, route, journey_pattern))
        end
      end
    end

    describe 'referential line show' do
      before(:each) { visit referential_line_path(referential, line) }

      context 'user has permission to edit routes' do
        it 'shows edit buttons for routes' do
          expect(page).to have_content(I18n.t('actions.edit'))
        end
      end

      context 'user does not have permission to edit routes' do
        it 'does not show edit buttons for routes' do
          user.update_attribute(:permissions, [])
          visit referential_line_path(referential, line)
          expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_line_route_path(referential, line, route))
        end
      end

      context 'user has permission to create routes' do
        it 'shows link to a create route page' do
          expect(page).to have_content(I18n.t('routes.actions.new'))
        end
      end

      context 'user belongs to another organisation' do
        xit 'does not show link to a create route page' do
          expect(page).not_to have_content(I18n.t('routes.actions.new'))
        end
      end

      context 'user does not have permission to create routes' do
        it 'does not show link to a create route page' do
          user.update_attribute(:permissions, [])
          visit referential_line_path(referential, line)
          expect(page).not_to have_content(I18n.t('routes.actions.new'))
        end
      end

      context 'user does not have permission to destroy routes' do
        it 'does not show destroy buttons for routes' do
          user.update_attribute(:permissions, [])
          visit referential_line_path(referential, line)
          expect(page).not_to have_link(I18n.t('actions.destroy'), href: referential_line_route_path(referential, line, route))
        end
      end
    end
  end
end
