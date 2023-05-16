RSpec.shared_examples_for 'Export::Scope::Base' do

	let!(:context) do
      Chouette.create do
        line :first
        line :second
        line :third

        stop_area :specific_stop

        workbench do
          shape :shape_in_scope1
          shape :shape_in_scope2
          shape

          referential lines: [:first, :second, :third] do
            time_table :default

            route :in_scope1, line: :first do
              journey_pattern :in_scope1, shape: :shape_in_scope1 do
                vehicle_journey :in_scope1, time_tables: [:default]
              end
              journey_pattern :in_scope2, shape: :shape_in_scope1 do
                vehicle_journey :in_scope2, time_tables: [:default]
              end
            end
            route :in_scope2, line: :second do
              journey_pattern :in_scope3, shape: :shape_in_scope2 do
                vehicle_journey :in_scope3, time_tables: [:default]
              end
            end
          end
        end
      end
    end

		let(:default_scope) { Export::Scope::All.new(context.referential) }
		let(:vehicle_journeys_in_scope) { [:in_scope1, :in_scope2, :in_scope3].map { |n| context.vehicle_journey(n) } }
    let(:routes_in_scope) { vehicle_journeys_in_scope.map(&:route).uniq }
    let(:journey_patterns_in_scope) { vehicle_journeys_in_scope.map(&:journey_pattern).uniq }
		let(:lines_in_scope) { vehicle_journeys_in_scope.map(&:line).uniq }

		let(:scope) do
			case described_class.to_s
			when 'Export::Scope::Lines' then Export::Scope::Scheduled.new(Export::Scope::Lines.new(default_scope, lines_in_scope))
			when 'Export::Scope::DateRange' then Export::Scope::Scheduled.new(Export::Scope::DateRange.new(default_scope, Time.zone.today..1.month.from_now.to_date))
			when 'Export::Scope::Scheduled' then Export::Scope::Scheduled.new(default_scope)
      else
        raise 'Base sub class not supported'
			end
		end

		before do
      context.referential.switch
    end

		let(:selected_vj) { context.vehicle_journey(:in_scope1) }
    let(:selected_lines) { [ selected_vj.line ] }
    let(:line_scope) { Export::Scope::Lines.new(default_scope, selected_lines) }
    let(:vehicle_journey_at_stops_via_selected_vj) { selected_vj.line.routes.map(&:vehicle_journey_at_stops).flatten.uniq }

    describe "stop_areas" do

      let(:stop_areas_in_scope) { routes_in_scope.flat_map(&:stop_areas).uniq }

      it "select stop areas associated with routes through vehicle journeys" do
        expect(scope.stop_areas).to match_array(stop_areas_in_scope)
      end

      it "select stop areas associated with routes through vehicle journeys (2)" do
        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

        expect(scope.stop_areas).not_to match_array(stop_areas_in_scope)
				expect(scope.stop_areas).to match_array(selected_vj.route.stop_areas)
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
        routes_in_scope.flat_map(&:stop_points).uniq
      end

      it "select stop points associated with routes through vehicle_journeys" do
        expect(scope.stop_points).to match_array(stop_points_in_scope)

        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

				expect(scope.stop_points).not_to match_array(stop_points_in_scope)
				expect(scope.stop_points).to match_array(selected_vj.route.stop_points)
      end

      it "doesn't provide a Stop Point twice" do
        expect(scope.stop_points).to be_uniq
      end

    end

    describe "routes" do

      it "select routes associated with vehicle journeys in scope" do
        expect(scope.routes).to match_array(routes_in_scope)

        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

				expect(scope.routes).not_to match_array(routes_in_scope)
				expect(scope.routes).to match_array([selected_vj.route])
      end

      it "doesn't provide a Route twice" do
        expect(scope.routes).to be_uniq
      end
    end

    describe "journey_patterns" do

      it "select journey patterns associated with vehicle journeys in scope" do
        expect(scope.journey_patterns).to match_array(journey_patterns_in_scope)

        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

				expect(scope.journey_patterns).not_to match_array(journey_patterns_in_scope)
				expect(scope.journey_patterns).to match_array([selected_vj.journey_pattern])
      end

      it "doesn't provide a Journey Pattern twice" do
        expect(scope.journey_patterns).to be_uniq
      end

    end

    describe "vehicle_journeys" do

      # it "select vehicle journeys with a time table in the date range" do
      #   expect(scope.vehicle_journeys).to eq(vehicle_journeys_in_scope)
      # end

    end

    describe "lines" do
      # it "select lines associated to vehicle journeys in date range" do
      #   expect(scope.lines).to eq(lines_with_vehicle_journeys)
      # end

      it "select lines associated to vehicle journeys" do
        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

				expect(scope.lines).not_to match_array(lines_in_scope)
				expect(scope.lines).to match_array(selected_lines)
      end

      it "doesn't provide a line twice" do
        expect(scope.lines).to be_uniq
      end

    end

    describe "vehicle_journeys_at_stops" do

      let(:vehicle_journey_at_stops_in_scope) do
        vehicle_journeys_in_scope.flat_map(&:vehicle_journey_at_stops)
      end

      # it "select all VehicleJourneyAtStops associated to vehicle journeys in date range" do
      #   expect(scope.vehicle_journey_at_stops).to match_array(vehicle_journey_at_stops_in_scope)
      # end

      it "select all VehicleJourneyAtStops associated to vehicle journeys" do
        expect(scope.vehicle_journey_at_stops).to match_array(vehicle_journey_at_stops_in_scope)

        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

        expect(scope.vehicle_journey_at_stops).not_to match_array(vehicle_journey_at_stops_in_scope)
        expect(scope.vehicle_journey_at_stops).to match_array(selected_vj.vehicle_journey_at_stops)
      end

      it "doesn't provide a VehicleJourneyAtStop twice" do
        expect(scope.vehicle_journey_at_stops).to be_uniq
      end

    end

    describe "shapes" do

      it "select shapes associated with journey patterns in scope" do
        shapes_in_scope = journey_patterns_in_scope.map(&:shape).uniq

				expect(scope.shapes).to match_array(shapes_in_scope)

        allow(scope).to receive(:final_scope_vehicle_journeys) { [selected_vj] }

				expect(scope.shapes).not_to match_array(shapes_in_scope)
				expect(scope.shapes).to match_array([selected_vj.journey_pattern.shape])
      end

      it "doesn't provide a Shape twice" do
        expect(scope.shapes).to be_uniq
      end

    end
end
