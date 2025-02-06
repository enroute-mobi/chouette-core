# frozen_string_literal: true

RSpec.describe Control::PresenceAssociatedModel do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::PresenceAssociatedModel::Run do
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :collection }
    it do
      should enumerize(:target_model).in(
        %w[Line StopArea Route JourneyPattern VehicleJourney TimeTable]
      )
    end

    describe '#candidate_collections' do
      subject { described_class.new.candidate_collections }

      it 'does not cause error' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:min) { nil }
    let(:max) { nil }
    let(:control_run) do
      Control::PresenceAssociatedModel::Run.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: {
          target_model: target_model,
          collection: collection,
          minimum: min,
          maximum: max
        },
        position: 0
      )
    end

    describe '#run' do
      subject { control_run.run }

      let(:referential) { context.referential }

      let(:expected_message) do
        an_object_having_attributes(source: source,
                                    criticity: 'warning',
                                    message_attributes: { 'name' => attribute_name, 'count' => be_present })
      end

      before do
        referential.switch
        subject
      end

      describe 'StopArea' do
        let(:source) { context.stop_area(:stop_area) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'StopArea' }

        context 'lines' do
          let(:collection) { 'lines' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                line :line1
                referential lines: %i[line1] do
                  route line: :line1, stop_areas: %i[stop_area]
                end
              end
            end

            context 'with minimum only' do
              let(:min) { 2 }

              it 'should create warning message' do
                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'with both minimum and maximum' do
              let(:min) { 2 }
              let(:max) { 3 }

              it 'should create warning message' do
                expect(control_run.control_messages).to include(expected_message)
              end
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                line :line1
                referential lines: %i[line1] do
                  route line: :line1, stop_areas: %i[stop_area]
                end
              end
            end

            context 'with minimum only' do
              let(:min) { 1 }

              it 'should not create warning message' do
                expect(control_run.control_messages).not_to include(expected_message)
              end
            end

            context 'with both minimum and maximum' do
              let(:min) { 1 }
              let(:max) { 2 }

              it 'should not create warning message' do
                expect(control_run.control_messages).not_to include(expected_message)
              end

              context 'when associated several times to the exact same model' do
                let(:context) do
                  Chouette.create do
                    stop_area :stop_area
                    line :line1
                    referential lines: %i[line1] do
                      route line: :line1, stop_areas: %i[stop_area]
                      route line: :line1, stop_areas: %i[stop_area]
                      route line: :line1, stop_areas: %i[stop_area]
                    end
                  end
                end

                it 'should not create warning message' do
                  expect(control_run.control_messages).not_to include(expected_message)
                end
              end
            end

            context 'with maximum only' do
              let(:max) { 2 }

              it 'should not create warning message' do
                expect(control_run.control_messages).not_to include(expected_message)
              end
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                line :line1
                line :line2
                line :line3
                referential lines: %i[line1 line2 line3] do
                  route line: :line1, stop_areas: %i[stop_area]
                  route line: :line2, stop_areas: %i[stop_area]
                  route line: :line3, stop_areas: %i[stop_area]
                end
              end
            end

            context 'with maximum only' do
              let(:max) { 2 }

              it 'should create warning message' do
                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'with both minimum and maximum' do
              let(:min) { 1 }
              let(:max) { 2 }

              it 'should create warning message' do
                expect(control_run.control_messages).to include(expected_message)
              end
            end
          end
        end

        context 'routes' do
          let(:collection) { 'routes' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                referential do
                  route stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                referential do
                  route stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                line :line1
                line :line2
                line :line3
                referential lines: %i[line1 line2 line3] do
                  route line: :line1, stop_areas: %i[stop_area]
                  route line: :line2, stop_areas: %i[stop_area]
                  route line: :line3, stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        context 'fare_zones' do
          let(:collection) { 'fare_zones' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                fare_zone :fare_zone1
                stop_area :stop_area do
                  stop_area_zone zone: :fare_zone1
                end
                referential do
                  route stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end

            context 'when minimum is 1' do
              let(:context) do
                Chouette.create do
                  stop_area :stop_area
                  referential do
                    route stop_areas: %i[stop_area]
                  end
                end
              end
              let(:min) { 1 }

              it 'should create warning message' do
                expect(control_run.control_messages).to include(expected_message)
              end
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                fare_zone :fare_zone1
                stop_area :stop_area do
                  stop_area_zone zone: :fare_zone1
                end
                referential do
                  route stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                fare_zone :fare_zone1
                fare_zone :fare_zone2
                fare_zone :fare_zone3
                stop_area :stop_area do
                  stop_area_zone zone: :fare_zone1
                  stop_area_zone zone: :fare_zone2
                  stop_area_zone zone: :fare_zone3
                end
                referential do
                  route stop_areas: %i[stop_area]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'Lines' do
        let(:source) { context.line(:line) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'Line' }

        context 'routes' do
          let(:collection) { 'routes' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                line :line
                referential lines: %i[line] do
                  route line: :line
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                line :line
                referential lines: %i[line] do
                  route line: :line
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                stop_area :stop_area
                line :line
                referential lines: %i[line] do
                  route line: :line
                  route line: :line
                  route line: :line
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'Routes' do
        let(:source) { context.route(:route) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'Route' }

        context 'stop_points' do
          let(:collection) { 'stop_points' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route, with_stops: false do
                    stop_point
                  end
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route, with_stops: false do
                    stop_point
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route, with_stops: false do
                    stop_point
                    stop_point
                    stop_point
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        context 'journey_patterns' do
          let(:collection) { 'journey_patterns' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    journey_pattern
                  end
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    journey_pattern
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    journey_pattern
                    journey_pattern
                    journey_pattern
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        context 'vehicle_journeys' do
          let(:collection) { 'vehicle_journeys' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  route :route do
                    vehicle_journey
                    vehicle_journey
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'JourneyPattern' do
        let(:source) { context.journey_pattern(:journey_pattern) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'JourneyPattern' }

        context 'stop_points' do
          let(:collection) { 'stop_points' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  route with_stops: false do
                    stop_point
                    stop_point
                    journey_pattern :journey_pattern
                  end
                end
              end
            end
            let(:min) { 3 }
            let(:max) { 4 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  route with_stops: false do
                    stop_point
                    stop_point
                    journey_pattern :journey_pattern
                  end
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  route with_stops: false do
                    stop_point
                    stop_point
                    stop_point
                    journey_pattern :journey_pattern
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        context 'vehicle_journeys' do
          let(:collection) { 'vehicle_journeys' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  journey_pattern :journey_pattern do
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  journey_pattern :journey_pattern do
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  journey_pattern :journey_pattern do
                    vehicle_journey
                    vehicle_journey
                    vehicle_journey
                  end
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'VehicleJourney' do
        let(:source) { context.vehicle_journey(:vehicle_journey) }
        let(:attribute_name) { nil } # FIXME: CHOUETTE-3397
        let(:target_model) { 'VehicleJourney' }

        context 'time_tables' do
          let(:collection) { 'time_tables' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table1
                  vehicle_journey :vehicle_journey, time_tables: %i[time_table1]
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table1
                  vehicle_journey :vehicle_journey, time_tables: %i[time_table1]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table1
                  time_table :time_table2
                  time_table :time_table3
                  vehicle_journey :vehicle_journey, time_tables: %i[time_table1 time_table2 time_table3]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end

      describe 'TimeTable' do
        let(:context) do
          Chouette.create do
            referential do
              time_table :time_table,
                         periods: [Date.parse('2024-01-18')..Date.parse('2024-01-20')],
                         dates_included: [Date.parse('2024-01-19')]
            end
          end
        end

        let(:source) { context.time_table(:time_table) }
        let(:attribute_name) { nil } # FIXME: CHOUETTE-3397
        let(:target_model) { 'TimeTable' }

        context 'periods' do
          let(:collection) { 'periods' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             periods: [Date.parse('2024-01-18')..Date.parse('2024-01-20')]
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             periods: [Date.parse('2024-01-18')..Date.parse('2024-01-20')]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             periods: [
                               Date.parse('2024-01-18')..Date.parse('2024-01-20'),
                               Date.parse('2024-01-22')..Date.parse('2024-01-24'),
                               Date.parse('2024-01-26')..Date.parse('2024-01-28')
                             ]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end

        context 'dates' do
          let(:collection) { 'dates' }

          context 'when number of model associated is lower than mininum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             dates_included: [Date.parse('2024-01-19')]
                end
              end
            end
            let(:min) { 2 }
            let(:max) { 3 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in bounds' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             dates_included: [Date.parse('2024-01-19')]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should not create warning message' do
              expect(control_run.control_messages).not_to include(expected_message)
            end
          end

          context 'when number of model associated is higher than maxinum' do
            let(:context) do
              Chouette.create do
                referential do
                  time_table :time_table,
                             dates_included: [
                               Date.parse('2024-01-19'),
                               Date.parse('2024-01-23'),
                               Date.parse('2024-01-27')
                             ]
                end
              end
            end
            let(:min) { 1 }
            let(:max) { 2 }

            it 'should create warning message' do
              expect(control_run.control_messages).to include(expected_message)
            end
          end
        end
      end
    end
  end
end
