# frozen_string_literal: true

RSpec.describe Export::Gtfs::JourneyPatternDistances do
  let(:export_scope) { Export::Scope::All.new context.referential }
  let(:export) do
    Export::Gtfs.new export_scope: export_scope
  end

  subject(:part) do
    Export::Gtfs::JourneyPatternDistances.new export
  end

  describe '#perform' do
    subject { part.perform }

    let(:context) do
      Chouette.create do
        stop_area :departure
        stop_area :second
        stop_area :third
        stop_area :arrival

        route with_stops: false do
          stop_point :departure
          stop_point :second
          stop_point :third
          stop_point :arrival

          vehicle_journey
        end

        journey_pattern :journey_pattern_without_costs
        journey_pattern :journey_pattern_with_empty_costs_hash
      end
    end

    let(:vehicle_journey_at_stops) { referential.vehicle_journey_at_stops }
    let(:journey_pattern) { context.vehicle_journey.journey_pattern }
    let(:journey_pattern_without_costs) { context.journey_pattern(:journey_pattern_without_costs) }
    let(:journey_pattern_with_empty_costs_hash) { context.journey_pattern(:journey_pattern_with_empty_costs_hash) }

    let(:departure_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=0').first }
    let(:second_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=1').first }
    let(:third_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=2').first }
    let(:arrival_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=3').first }

    let(:departure_stop_point) { departure_at_stop.stop_point }
    let(:second_stop_point) { second_at_stop.stop_point }
    let(:third_stop_point) { third_at_stop.stop_point }
    let(:arrival_stop_point) { arrival_at_stop.stop_point }

    let(:departure_stop) { departure_at_stop.stop_point.stop_area }
    let(:second_stop) { second_at_stop.stop_point.stop_area }
    let(:third_stop) { third_at_stop.stop_point.stop_area }
    let(:arrival_stop) { arrival_at_stop.stop_point.stop_area }

    before do
      context.referential.switch

      journey_pattern.update costs: {
        "#{departure_stop.id}-#{second_stop.id}" => { 'distance' => 1 },
        "#{second_stop.id}-#{third_stop.id}" => { 'distance' => 2 },
        "#{third_stop.id}-#{arrival_stop.id}" => { 'distance' => 3 }
      }

      journey_pattern_without_costs.update costs: nil
    end

    def distance(journey_pattern, stop_point)
      export.index.journey_pattern_distance(journey_pattern.id, stop_point.id)
    end

    it { expect(part.journey_patterns).not_to include(journey_pattern_without_costs) }

    it { expect(part.journey_patterns).not_to include(journey_pattern_with_empty_costs_hash) }

    it { expect(part.journey_patterns).to include(journey_pattern) }

    context 'for departure stop_point' do
      it { expect { subject }.to change { distance journey_pattern, departure_stop_point }.from(nil).to(0) }
    end

    context 'for second stop_point' do
      it { expect { subject }.to change { distance journey_pattern, second_stop_point }.from(nil).to(1) }
    end

    context 'for third stop_point' do
      it { expect { subject }.to change { distance journey_pattern, third_stop_point }.from(nil).to(3) }
    end

    context 'for arrival stop_point' do
      it { expect { subject }.to change { distance journey_pattern, arrival_stop_point }.from(nil).to(6) }
    end
  end
end
