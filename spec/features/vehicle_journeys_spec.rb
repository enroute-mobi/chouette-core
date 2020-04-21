
describe 'VehicleJourneys', type: :feature do
  login_user

  let(:referential) { Referential.first }
  let!(:line) { create(:line, referential: referential) }
  let!(:route) { create(:route, line: line) }
  let!(:journey_pattern) { create(:journey_pattern, route: route) }
  let!(:vehicle_journey) { create(:vehicle_journey, journey_pattern: journey_pattern) }

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
