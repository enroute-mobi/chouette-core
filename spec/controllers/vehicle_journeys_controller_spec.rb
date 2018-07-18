RSpec.describe VehicleJourneysController, :type => :controller do

  before do
    @user = build_stubbed(:allmighty_user)
  end

  describe 'user_permissions' do
    let( :referential ){ build_stubbed(:referential) }
    let( :user_context ){ UserContext.new(@user, referential: referential) }

    before do
      allow(controller).to receive(:pundit_user).and_return(user_context)
      allow(controller).to receive(:current_organisation).and_return(@user.organisation)
    end

    it 'computes them correctly if not authorized' do
      expect( controller.send(:user_permissions) ).to eq({'vehicle_journeys.create'  => false,
                                                   'vehicle_journeys.destroy' => false,
                                                   'vehicle_journeys.update'  => false }.to_json)
    end
    it 'computes them correctly if authorized' do
      @user.organisation_id = referential.organisation_id
      expect( controller.send(:user_permissions) ).to eq({'vehicle_journeys.create'  => true,
                                                   'vehicle_journeys.destroy' => true,
                                                   'vehicle_journeys.update'  => true }.to_json)
    end
  end

  describe "GET index" do
    login_user
    render_views

    context "in JSON" do
      let!(:vehicle_journey){ create :vehicle_journey, journey_pattern: route.full_journey_pattern }
      let(:route){ create :route, referential: referential }
      let(:line){ route.line }
      let!(:request){ get :index, referential_id: referential.id, line_id: line.id, route_id: route.id, format: :json}
      let(:parsed_response){ JSON.parse response.body }
      it "should have all the attributes" do
        expect(response).to have_http_status 200
        vehicle_journey = parsed_response["vehicle_journeys"].first
        vehicle_journey_at_stops_matrix = vehicle_journey["vehicle_journey_at_stops"]
        vehicle_journey_at_stops_matrix.each do |received_vjas|
          expect(received_vjas).to have_key("id")
          vjas = Chouette::VehicleJourneyAtStop.find received_vjas["id"]
          [:connecting_service_id, :boarding_alighting_possibility].each do |att|
            expect(received_vjas[att]).to eq vjas.send(att)
          end
        end
      end
    end
  end
end
