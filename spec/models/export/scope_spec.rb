RSpec.describe Export::Scope, use_chouette_factory: true do

  describe "Base" do

    describe "stop_areas" do

      it "uses workbench stop areas" do
        referential = double(workbench: double(stop_areas: double))

        expect(Export::Scope::Base.new(referential).stop_areas).
          to be(referential.workbench.stop_areas)
      end

      context "without workbench" do
        it "uses stop areas from stop area referential" do
          referential = double(workbench: nil,
                               stop_area_referential: double(stop_areas: double))

          expect(Export::Scope::Base.new(referential).stop_areas).
            to be(referential.stop_area_referential.stop_areas)
        end
      end

    end

    describe "lines" do

      it "uses workbench lines" do
        referential = double(workbench: double(lines: double))

        expect(Export::Scope::Base.new(referential).lines).
          to be(referential.workbench.lines)
      end

      context "without workbench" do
        it "uses lines from line referential" do
          referential = double(workbench: nil,
                               line_referential: double(lines: double))

          expect(Export::Scope::Base.new(referential).lines).
            to be(referential.line_referential.lines)
        end
      end

    end

  end

  describe "DateRange" do

    let!(:context) do
      Chouette.create do
        line :first
        line :second
        line :third

        stop_area :specific_stop

        referential lines: [:first, :second, :third] do
          time_table :default

          route :in_scope1, line: :first do
            vehicle_journey :in_scope1, time_tables: [:default]
            vehicle_journey :in_scope2, time_tables: [:default]
          end
          route :in_scope2, line: :second do
            vehicle_journey :in_scope3, time_tables: [:default]
            vehicle_journey # no timetable
          end
          route
        end
      end
    end

    # around(:each) lets models in database after spec (?!)
    before do
      context.referential.switch
    end

    let(:date_range) { context.time_table(:default).date_range }
    let(:scope) { Export::Scope::DateRange.new context.referential, date_range }

    let(:vehicle_journeys_in_scope) do
      [:in_scope1, :in_scope2, :in_scope3].map { |n| context.vehicle_journey(n) }
    end

    let(:routes_in_scope) { [:in_scope1, :in_scope2].map { |n| context.route(n) } }

    describe "stop_areas" do

      let(:stop_areas_in_scope) { routes_in_scope.map(&:stop_areas).flatten.uniq }

      it "select stop areas associated with routes" do
        expect(scope.stop_areas).to match_array(stop_areas_in_scope)
      end

      it "doesn't provide a Stop Area twice" do
        expect(scope.stop_areas).to be_uniq
      end

      context "when a VehicleJourneyAtStop has a specific Stop" do

        let(:vehicle_journey_at_stop) do
          vehicle_journeys_in_scope.sample.vehicle_journey_at_stops.sample
        end
        let(:specific_stop) { context.stop_area(:specific_stop) }

        before do
          vehicle_journey_at_stop.update stop_area: specific_stop
        end

        it "select specific stops" do
          expect(scope.stop_areas).to include(specific_stop)
        end

      end

    end

    describe "stop_points" do

      let(:stop_points_in_scope) do
        routes_in_scope.map(&:stop_points).flatten.uniq
      end

      it "select stop points associated with routes" do
        expect(scope.stop_points).to match_array(stop_points_in_scope)
      end

      it "doesn't provide a Stop Point twice" do
        expect(scope.stop_points).to be_uniq
      end

    end

    describe "routes" do

      it "select routes associated with vehicle journeys in scope" do
        expect(scope.routes).to match_array(routes_in_scope)
      end

      it "doesn't provide a Route twice" do
        expect(scope.routes).to be_uniq
      end

    end

    describe "vehicle_journeys" do

      it "select vehicle journeys with a time table in the date range" do
        expect(scope.vehicle_journeys).to eq(vehicle_journeys_in_scope)
      end

    end

    describe "lines" do

      let(:lines_with_vehicle_journeys) { [context.line(:first), context.line(:second)] }

      it "select lines associated to vehicle journeys in date range" do
        expect(scope.lines).to eq(lines_with_vehicle_journeys)
      end

      it "doesn't provide a line twice" do
        expect(scope.lines).to be_uniq
      end

    end

    describe "vehicle_journeys_at_stops" do

      let(:vehicle_journey_at_stops_in_scope) do
        vehicle_journeys_in_scope.map(&:vehicle_journey_at_stops).flatten
      end

      it "select all VehicleJourneyAtStops associated to vehicle journeys in date range" do
        expect(scope.vehicle_journey_at_stops).to match_array(vehicle_journey_at_stops_in_scope)
      end

      it "doesn't provide a VehicleJourneyAtStop twice" do
        expect(scope.vehicle_journey_at_stops).to be_uniq
      end

    end

  end

end
