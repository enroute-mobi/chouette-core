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
      end

      describe 'StopArea' do
        let(:context) do
          Chouette.create do
            stop_area :stop_area
            referential do
              route :route, stop_areas: [:stop_area]
            end
          end
        end

        let(:source) { context.stop_area(:stop_area) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'StopArea' }

        %w[
          routes
          lines
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
            end
          end
        end
      end

      describe 'Lines' do
        let(:context) do
          Chouette.create do
            line :line
            referential lines: [:line] do
              route
            end
          end
        end

        let(:source) { context.line(:line) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'Line' }

        %w[
          routes
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
            end
          end
        end
      end

      describe 'Routes' do
        let(:context) do
          Chouette.create do
            referential do
              route :route do
                journey_pattern do
                  vehicle_journey
                end
              end
            end
          end
        end

        let(:source) { context.route(:route) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'Route' }

        %w[
          stop_points
          journey_patterns
          vehicle_journeys
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
            end
          end
        end
      end

      describe 'JourneyPattern' do
        let(:context) do
          Chouette.create do
            referential do
              journey_pattern :journey_pattern do
                vehicle_journey
              end
            end
          end
        end

        let(:source) { context.journey_pattern(:journey_pattern) }
        let(:attribute_name) { source.name }
        let(:target_model) { 'JourneyPattern' }

        %w[
          stop_points
          vehicle_journeys
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
            end
          end
        end
      end

      describe 'VehicleJourney' do
        let(:context) do
          Chouette.create do
            referential do
              time_table :time_table
              vehicle_journey :vehicle_journey, time_tables: [:time_table]
            end
          end
        end

        let(:source) { context.vehicle_journey(:vehicle_journey) }
        let(:attribute_name) { nil } # FIXME: CHOUETTE-3397
        let(:target_model) { 'VehicleJourney' }

        %w[
          time_tables
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
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

        %w[
          periods
          dates
        ].each do |collection|
          describe "##{collection}" do
            let(:collection) { collection }

            context 'when number of model associated is not in the range [min, max]' do
              let(:min) { 9 }
              let(:max) { 10 }

              it 'should create warning message' do
                subject

                expect(control_run.control_messages).to include(expected_message)
              end
            end

            context 'when number of model associated is in the range [min, max]' do
              let(:min) { 1 }
              let(:max) { 10 }

              it 'should not create warning message' do
                subject

                expect(control_run.control_messages).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
