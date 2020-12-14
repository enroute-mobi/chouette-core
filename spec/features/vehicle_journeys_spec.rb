describe 'VehicleJourneys', type: :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        vehicle_journey
      end
    end
  end

  let(:referential) { context.referential }
  let(:line) { route.line }
  let(:route) { journey_pattern.route }
  let(:journey_pattern) { vehicle_journey.journey_pattern }
  let(:vehicle_journey) { context.vehicle_journey }

  describe 'show' do
    context 'user has permissions' do
      before(:each) { visit referential_line_route_vehicle_journey_path(referential, line, route, vehicle_journey) }

      context 'user has permission to create vehicle journeys' do
        it 'shows a create link for vehicle journeys' do
          expect(page).to have_content(I18n.t('vehicle_journeys.actions.new'))
        end
      end

      context 'user has permission to edit vehicle journeys' do
        it 'shows an edit link for vehicle journeys' do
          expect(page).to have_content(I18n.t('vehicle_journeys.actions.edit'))
        end
      end

      context 'user has permission to destroy vehicle journeys' do
        it 'shows a destroy link for vehicle journeys' do
          expect(page).to have_content(I18n.t('vehicle_journeys.actions.destroy'))
        end
      end
    end

    context 'user does not have permissions' do
      context 'user does not have permission to create vehicle journeys' do
        it 'does not show a create link for vehicle journeys' do
          @user.tap { |u| u.permissions.delete('vehicle_journeys.create') }.save
          visit referential_line_route_vehicle_journey_path(referential, line, route, vehicle_journey)
          expect(page).not_to have_content(I18n.t('vehicle_journeys.actions.new'))
        end
      end

      context 'user does not have permission to edit vehicle journeys' do
        it 'does not show an edit link for vehicle journeys' do
          @user.tap { |u| u.permissions.delete('vehicle_journeys.update') }.save
          visit referential_line_route_vehicle_journey_path(referential, line, route, vehicle_journey)
          expect(page).not_to have_content(I18n.t('vehicle_journeys.actions.edit'))
        end
      end

      context 'user does not have permission to edit vehicle journeys' do
        it 'does not show a destroy link for vehicle journeys' do
          @user.tap { |u| u.permissions.delete('vehicle_journeys.destroy') }.save
          visit referential_line_route_vehicle_journey_path(referential, line, route, vehicle_journey)
          expect(page).not_to have_content(I18n.t('vehicle_journeys.actions.destroy'))
        end
      end
    end
  end
end
