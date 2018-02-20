require "rails_helper"

RSpec.describe ReferentialVehicleJourneysController, type: :controller do
  login_user

  before do
    @user.organisation.update features: %w{referential_vehicle_journeys}
  end

  describe 'GET #index' do
    it 'should be successful' do
      get :index, referential_id: referential
      expect(response).to be_success
    end

    it "refuse access when organisation does not have the feature 'referential_vehicle_journeys'" do
      @user.organisation.update features: []

      expect do
        get :index, referential_id: referential
      end.to raise_error(FeatureChecker::NotAuthorizedError)
    end

    it 'define Ransack search (alias @q)' do
      get :index, referential_id: referential
      expect(assigns[:q]).to be_an_instance_of(Ransack::Search)
    end

    it 'define @vehicle_journeys collection' do
      vehicle_journey = FactoryGirl.create :vehicle_journey
      get :index, referential_id: referential
      expect(assigns[:vehicle_journeys]).to include(vehicle_journey)
    end

    it 'paginage @vehicle_journeys collection' do
      FactoryGirl.create :vehicle_journey

      get :index, referential_id: referential
      expect(assigns[:vehicle_journeys].total_entries).to be(1)
    end

    context "when filtered on stop areas" do
      let!(:request){
        get :index, referential_id: referential, q: q
      }

      let(:from_area_id){ nil }
      let(:to_area_id){ nil }

      def create_journey_pattern_with_stop_areas(*stop_areas)
        j = create(:journey_pattern)
        stop_areas.each do |area|
          sp = create(:stop_point, stop_area: area)
          j.stop_points << sp
        end
        j.save
        j
      end

      let(:q){ {stop_areas: {start: from_area_id, end: to_area_id}} }
      let(:journey_pattern){ create(:journey_pattern) }
      let(:journey_pattern_2){ create(:journey_pattern) }

      let!(:vehicle_journey_1){ create(:vehicle_journey, journey_pattern: journey_pattern)}
      let!(:vehicle_journey_2){ create(:vehicle_journey, journey_pattern: journey_pattern_2)}

      context "with the start stop" do
        let(:from_area_id){ vehicle_journey_1.stop_areas.first.id }
        it "should apply filters" do
          expect(assigns[:vehicle_journeys]).to include(vehicle_journey_1)
          expect(assigns[:vehicle_journeys]).to_not include(vehicle_journey_2)
        end
      end

      context "with both stops" do
        let(:from_area_id){ vehicle_journey_1.stop_areas.first.id }
        let(:to_area_id){ vehicle_journey_1.stop_areas.last.id }
        it "should apply filters" do
          expect(assigns[:vehicle_journeys]).to include(vehicle_journey_1)
          expect(assigns[:vehicle_journeys]).to_not include(vehicle_journey_2)
        end
      end
    end
  end

end
