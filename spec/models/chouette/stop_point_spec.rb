# frozen_string_literal: true

RSpec.describe Chouette::StopPoint, type: :model do
  subject(:stop_point) { route.stop_points.first }

  let(:context) do
    referential_objectid_format = self.referential_objectid_format
    Chouette.create do
      referential objectid_format: referential_objectid_format do
        route
      end
    end
  end
  let(:referential_objectid_format) { 'netex' }
  let(:referential) { context.referential }
  let(:route) { context.route }

  before { referential.switch }

  it { is_expected.to validate_uniqueness_of :objectid }

  describe '#flexible?' do
    subject { stop_point.flexible? }

    it { is_expected.to be_falsy }
  end

  describe '#stop_area validation' do
    let(:context) do
      Chouette.create do
        stop_area
        referential do
          route
        end
      end
    end
    let(:stop_area) { context.stop_area }

    it 'should validate a valid StopArea is associated' do
      stop_point = route.stop_points.new(stop_area_id: nil)
      expect(stop_point).to_not be_valid
      stop_point.stop_area_id = Chouette::StopArea.last.id + 1
      expect(stop_point).to_not be_valid
      stop_point.stop_area_id = stop_area.id
      expect(stop_point).to be_valid
    end
  end

  describe '#objectid' do
    subject { stop_point.get_objectid }

    let(:referential_objectid_format) { 'stif_netex' }

    it { is_expected.to be_kind_of(Chouette::Objectid::StifNetex) }
  end

  describe "#destroy" do
    subject { stop_point.destroy }

    let(:context) do
      Chouette.create do
        referential do
          route do
            vehicle_journey
          end
        end
      end
    end
    let(:vehicle_journey) { context.vehicle_journey }

    def vjas_stop_point_ids( vehicle_id)
      Chouette::VehicleJourney.find( vehicle_id).vehicle_journey_at_stops.map(&:stop_point_id)
    end

    def jpsp_stop_point_ids( journey_id)
      Chouette::JourneyPattern.find( journey_id).stop_points.map(&:id)
    end

    it "should remove dependent vehicle_journey_at_stop" do
      expect(vjas_stop_point_ids(vehicle_journey.id)).to include(stop_point.id)
      subject
      expect(vjas_stop_point_ids(vehicle_journey.id)).not_to include(stop_point.id)
    end

    it "should remove dependent journey_pattern_stop_point" do
      expect(jpsp_stop_point_ids(vehicle_journey.journey_pattern_id)).to include(stop_point.id)
      subject
      expect(jpsp_stop_point_ids(vehicle_journey.journey_pattern_id)).not_to include(stop_point.id)
    end
  end

  describe '#duplicate' do
    let!( :new_route ){ create :route }

    it 'creates a new instance' do
      expect{ subject.duplicate(for_route: new_route) }.to change{ Chouette::StopPoint.count }.by(1)
    end
    it 'new instance has a new route' do
      expect(subject.duplicate(for_route: new_route).route).to eq(new_route)
    end
    it 'and old stop_area' do
      expect(subject.duplicate(for_route: new_route).stop_area).to eq(subject.stop_area)
    end
  end
end
