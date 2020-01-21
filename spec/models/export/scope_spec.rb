RSpec.describe Export::Scope, use_chouette_factory: true do

  describe "DateRange" do

    let!(:context) do
      Chouette.create do
        line :first
        line :second
        line :third

        referential lines: [:first, :second, :third] do
          time_table :default

          route line: :first do
            vehicle_journey :in_range1, time_tables: [:default]
            vehicle_journey :in_range2, time_tables: [:default]
          end
          route line: :second do
            vehicle_journey :in_range3, time_tables: [:default]
            vehicle_journey # no timetable
          end
        end
      end
    end

    around(:each) do |example|
      context.referential.switch(&example)
    end

    let(:date_range) { context.time_table(:default).date_range }
    let(:scope) { Export::Scope::DateRange.new context.referential, date_range }

    let(:vehicle_journeys_in_range) do
      [:in_range1, :in_range2, :in_range3].map { |n| context.vehicle_journey(n) }
    end

    describe "vehicle_journeys" do

      it "select vehicle journeys with a time table in the date range" do
        expect(scope.vehicle_journeys).to eq(vehicle_journeys_in_range)
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

      let(:vehicle_journey_at_stops_in_range) do
        vehicle_journeys_in_range.map(&:vehicle_journey_at_stops).flatten
      end

      it "select all VehicleJourneyAtStops associated to vehicle journeys in date range" do
        expect(scope.vehicle_journey_at_stops).to match_array(vehicle_journey_at_stops_in_range)
      end

      it "doesn't provide a VehicleJourneyAtStop twice" do
        expect(scope.vehicle_journey_at_stops).to be_uniq
      end

    end

  end

end
