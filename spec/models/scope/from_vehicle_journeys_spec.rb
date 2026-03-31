# frozen_string_literal: true

RSpec.describe Scope::FromVehicleJourneys do
  let(:scope) { described_class.new(time_tables: time_tables) }

  let(:time_tables) { true }

  describe '#scopes?' do
    subject { scope.scopes?(collection_name) }

    context 'when time_tables is true' do
      %i[
        footnotes
        lines
        line_notices
        booking_arrangements
        vehicle_journey_at_stops
        routes
        journey_patterns
        shapes
        stop_points
        routing_constraint_zones
        stop_areas
        time_tables
      ].each do |collection_name|
        context "with :#{collection_name}" do
          let(:collection_name) { collection_name }

          it { is_expected.to be(true) }
        end
      end

      context 'with garbage' do
        let(:collection_name) { :dummy }

        it { is_expected.to be(false) }
      end
    end

    context 'when time_tables is false' do
      let(:time_tables) { false }

      %i[
        footnotes
        lines
        line_notices
        booking_arrangements
        vehicle_journey_at_stops
        routes
        journey_patterns
        shapes
        stop_points
        routing_constraint_zones
        stop_areas
      ].each do |collection_name|
        context "with :#{collection_name}" do
          let(:collection_name) { collection_name }

          it { is_expected.to be(true) }
        end
      end

      context 'with :time_tables' do
        let(:collection_name) { :time_tables }

        it { is_expected.to be(false) }
      end

      context 'with garbage' do
        let(:collection_name) { :dummy }

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#collection' do
    subject { scope.collection(collection_name, current_collection: current_collection) }

    let(:current_collection) { nil }
    let(:global_scope) { double('glocal_scope') }
    let(:routes) { Chouette::Route.where(id: vehicle_journeys.select(:route_id)) }
    let(:journey_patterns) { Chouette::JourneyPattern.where(id: vehicle_journeys.select(:journey_pattern_id)) }
    let(:vehicle_journeys) { Chouette::VehicleJourney.where(id: context.vehicle_journey(:vehicle_journey)) }
    let(:allow_routes) { allow(global_scope).to receive(:routes).and_return(routes) }
    let(:allow_journey_patterns) { allow(global_scope).to receive(:journey_patterns).and_return(journey_patterns) }
    let(:allow_vehicle_journeys) { allow(global_scope).to receive(:vehicle_journeys).and_return(vehicle_journeys) }

    before do
      scope.global_scope = global_scope
      context.referential.switch
    end

    context 'with :footnotes' do
      let(:collection_name) { :footnotes }
      let(:current_collection) { Chouette::Footnote.all }

      let(:context) do
        Chouette.create do
          referential do
            footnote :footnote
            footnote :other_footnote

            vehicle_journey :vehicle_journey, footnotes: %i[footnote]
            vehicle_journey :other_vehicle_journey, footnotes: %i[other_footnote]
          end
        end
      end

      before { allow_vehicle_journeys }

      it 'returns only footnotes associated to vehicle journeys' do
        is_expected.to contain_exactly(context.footnote(:footnote))
      end
    end

    context 'with :lines' do
      let(:collection_name) { :lines }
      let(:current_collection) { Chouette::Line.all }

      let(:context) do
        Chouette.create do
          line :line
          line :other_line

          referential lines: %i[line other_line] do
            route line: :line do
              vehicle_journey :vehicle_journey
            end
            route line: :other_line do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_routes }

      it 'returns only lines associated to routes' do
        is_expected.to contain_exactly(context.line(:line))
      end
    end

    context 'with :line_notices' do
      let(:collection_name) { :line_notices }
      let(:current_collection) { Chouette::LineNotice.where(id: context.line_notice(:line_notice_current_collection)) }

      let(:context) do
        Chouette.create do
          line_notice :line_notice
          line_notice :line_notice_current_collection
          line_notice :other_line_notice

          vehicle_journey :vehicle_journey, line_notices: %i[line_notice]
          vehicle_journey :other_vehicle_journey, line_notices: %i[other_line_notice]
        end
      end

      before { allow_vehicle_journeys }

      it 'adds line notices associated to vehicle journeys to current collection' do
        is_expected.to match_array(%i[line_notice line_notice_current_collection].map { |i| context.line_notice(i) })
      end
    end

    context 'with :booking_arrangements' do
      let(:collection_name) { :booking_arrangements }
      let(:current_collection) do
        BookingArrangement.where(id: context.booking_arrangement(:booking_arrangement_current_collection))
      end

      let(:context) do
        Chouette.create do
          booking_arrangement :booking_arrangement
          booking_arrangement :booking_arrangement_current_collection
          booking_arrangement :other_booking_arrangement

          journey_pattern booking_arrangement: :booking_arrangement do
            vehicle_journey :vehicle_journey
          end
          journey_pattern booking_arrangement: :booking_arrangement_current_collection do
            vehicle_journey :other_vehicle_journey
          end
        end
      end

      before { allow_journey_patterns }

      it 'adds booking arrangments associated to journey patterns to current collection' do
        is_expected.to(
          match_array(
            %i[booking_arrangement booking_arrangement_current_collection].map { |i| context.booking_arrangement(i) }
          )
        )
      end
    end

    context 'with :vehicle_journey_at_stops' do
      let(:collection_name) { :vehicle_journey_at_stops }
      let(:current_collection) { Chouette::VehicleJourneyAtStop.all }

      let(:context) do
        Chouette.create do
          referential do
            vehicle_journey :vehicle_journey
            vehicle_journey :other_vehicle_journey
          end
        end
      end

      before { allow_vehicle_journeys }

      it 'returns only vehicle journey at stops associated to vehicle journeys' do
        is_expected.to match_array(context.vehicle_journey(:vehicle_journey).vehicle_journey_at_stops)
      end
    end

    context 'with :routes' do
      let(:collection_name) { :routes }
      let(:current_collection) { Chouette::Route.all }

      let(:context) do
        Chouette.create do
          referential do
            route :route do
              vehicle_journey :vehicle_journey
            end
            route :other_route do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_vehicle_journeys }

      it 'returns only routes associated to vehicle journeys' do
        is_expected.to contain_exactly(context.route(:route))
      end
    end

    context 'with :journey_patterns' do
      let(:collection_name) { :journey_patterns }
      let(:current_collection) { Chouette::JourneyPattern.all }

      let(:context) do
        Chouette.create do
          referential do
            journey_pattern :journey_pattern do
              vehicle_journey :vehicle_journey
            end
            journey_pattern :other_journey_pattern do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_vehicle_journeys }

      it 'returns only journey patterns associated to vehicle journeys' do
        is_expected.to contain_exactly(context.journey_pattern(:journey_pattern))
      end
    end

    context 'with :shapes' do
      let(:collection_name) { :shapes }
      let(:current_collection) { Shape.all }

      let(:context) do
        Chouette.create do
          shape :shape
          shape :other_shape

          referential do
            journey_pattern shape: :shape do
              vehicle_journey :vehicle_journey
            end
            journey_pattern shape: :other_shape do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_journey_patterns }

      it 'returns only shapes associated to journey patterns' do
        is_expected.to contain_exactly(context.shape(:shape))
      end
    end

    context 'with :stop_points' do
      let(:collection_name) { :stop_points }
      let(:current_collection) { Chouette::StopPoint.all }

      let(:context) do
        Chouette.create do
          referential do
            route :route do
              vehicle_journey :vehicle_journey
            end
            route :other_route do
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_routes }

      it 'returns only stop points associated to routes' do
        is_expected.to match_array(context.route(:route).stop_points)
      end
    end

    context 'with :routing_constraint_zones' do
      let(:collection_name) { :routing_constraint_zones }
      let(:current_collection) { Chouette::RoutingConstraintZone.all }

      let(:context) do
        Chouette.create do
          referential do
            route :route do
              routing_constraint_zone :rcz
              vehicle_journey :vehicle_journey
            end
            route :other_route do
              routing_constraint_zone :other_rcz
              vehicle_journey :other_vehicle_journey
            end
          end
        end
      end

      before { allow_routes }

      it 'returns only routing constraint zones associated to routes' do
        is_expected.to contain_exactly(context.routing_constraint_zone(:rcz))
      end
    end

    context 'with :stop_areas' do
      let(:collection_name) { :stop_areas }
      let(:current_collection) { Chouette::StopArea.all }

      let(:context) do
        Chouette.create do
          stop_area :sp_stop_area1
          stop_area :sp_stop_area2
          stop_area :vjas_stop_area
          stop_area :other_sp_stop_area1
          stop_area :other_sp_stop_area2
          stop_area :other_vjas_stop_area

          referential do
            route :vehicle_journey_route do
              vehicle_journey :vehicle_journey
            end
            route :stop_point_route, with_stops: false do
              stop_point :stop_point1, stop_area: :sp_stop_area1
              stop_point :stop_point2, stop_area: :sp_stop_area2
            end
            route :other_route, with_stops: false do
              stop_point :other_stop_point1, stop_area: :other_sp_stop_area1
              stop_point :other_stop_point2, stop_area: :other_sp_stop_area2
              vehicle_journey :other_vehicle_journey
            end
          end
        end.tap do |context|
          context.referential.switch do
            context.vehicle_journey(:vehicle_journey).vehicle_journey_at_stops.first.update!(
              stop_area: context.stop_area(:vjas_stop_area)
            )
            context.vehicle_journey(:other_vehicle_journey).vehicle_journey_at_stops.first.update!(
              stop_area: context.stop_area(:other_vjas_stop_area)
            )
          end
        end
      end

      before do
        allow(global_scope).to receive(:stop_points).and_return(
          Chouette::StopPoint.where(id: %i[stop_point1 stop_point2].map { |i| context.stop_point(i) })
        )
        allow(global_scope).to receive(:vehicle_journey_at_stops).and_return(
          Chouette::VehicleJourneyAtStop.where(id: context.vehicle_journey(:vehicle_journey).vehicle_journey_at_stops)
        )
      end

      it 'returns only stop areas associated to stop points and vehicle journey at stops' do
        is_expected.to(
          match_array(
            %i[sp_stop_area1 sp_stop_area2 vjas_stop_area].map { |i| context.stop_area(i) }
          )
        )
      end
    end

    context 'with :time_tables' do
      let(:collection_name) { :time_tables }
      let(:current_collection) { Chouette::TimeTable.all }

      let(:context) do
        Chouette.create do
          time_table :time_table
          time_table :other_time_table

          vehicle_journey :vehicle_journey, time_tables: %i[time_table]
          vehicle_journey :other_vehicle_journey, time_tables: %i[other_time_table]
        end
      end

      before { allow_vehicle_journeys }

      it 'reteurns only time tables associated to vehicle journeys' do
        is_expected.to contain_exactly(context.time_table(:time_table))
      end
    end
  end
end
