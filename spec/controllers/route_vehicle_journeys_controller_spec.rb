# frozen_string_literal: true

RSpec.describe RouteVehicleJourneysController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workbench(organisation: Organisation.find_by(code: 'first')) do
        referential do
          route do
            vehicle_journey
          end
        end
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }
  let(:route) { context.route }
  let(:vehicle_journey) { context.vehicle_journey }

  let(:base_params) do
    { 'workbench_id' => workbench.id, 'referential_id' => referential.id.to_s, 'route_id' => route.id.to_s }
  end
  let(:format) { nil }

  describe 'GET show' do
    subject { get :show, params: params, format: format }

    let(:params) { base_params }

    context 'in JSON' do
      render_views

      let(:format) { 'json' }
      let(:parsed_response) { JSON.parse(response.body) }

      it 'should have all the attributes' do
        subject

        expect(response).to have_http_status(:ok)

        vehicle_journey = parsed_response['vehicle_journeys'].first
        vehicle_journey['vehicle_journey_at_stops'].each do |received_vjas|
          expect(received_vjas).to have_key('id')
          vjas = Chouette::VehicleJourneyAtStop.find(received_vjas['id'])
          %i[connecting_service_id boarding_alighting_possibility].each do |att|
            expect(received_vjas[att]).to eq vjas.send(att)
          end
        end
      end

      it 'sets user permissions' do
        subject

        expect(JSON.parse(assigns(:features))).to be_a(Hash)
        expect(JSON.parse(assigns(:perms))).to eq(
          {
            'vehicle_journeys.create' => true,
            'vehicle_journeys.update' => true,
            'vehicle_journeys.destroy' => true
          }
        )
      end

      it 'when user is not authorized' do
        referential.update(archived_at: Time.zone.now)

        subject

        expect(JSON.parse(assigns(:features))).to be_a(Hash)
        expect(JSON.parse(assigns(:perms))).to eq(
          {
            'vehicle_journeys.create' => false,
            'vehicle_journeys.update' => false,
            'vehicle_journeys.destroy' => false
          }
        )
      end
    end
  end

  describe 'PUT update' do
    subject { put :update, params: params, body: [].to_json, format: format }

    let(:format) { 'json' }
    let(:params) { base_params }

    it 'should allow updates' do
      subject

      expect(response).to have_http_status(:ok)
    end

    context 'when the referential is in pending state' do
      before(:each) { referential.pending! }

      it 'should deny updates' do
        subject

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the referential is in archived state' do
      before(:each) { referential.archived! }

      it 'should deny updates' do
        subject

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
