require_relative './merge_context_helper'

describe Merge do
  %i[legacy experimental].each do |merge_method|
    context "with #{merge_method} method" do
      describe 'Metadatas merge' do
        context "when the merged Referential doesn't already exist" do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method, skip_cloning: false) do
              line :line1
              line :line2
              referential :source, lines: %i[line1 line2]
            end
          end
          let(:merge) { merge_context.merge }
          let(:source) { merge_context.source }

          let(:original_timestamp) { Time.now.beginning_of_day }
          before do
            source.metadatas.update_all created_at: original_timestamp, updated_at: original_timestamp
            merge.merge!
          end

          describe 'the merged Referential metadatas' do
            subject { merge.new.metadatas }

            it 'describes the same lines x periods than the source Referential' do
              expect(subject.line_periods).to eq(source.metadatas.line_periods)
            end

            it 'should use the source Referential id as referential_source_id' do
              is_expected.to all(have_attributes(referential_source_id: source.id))
            end

            it 'should keep the created_at timestamp of source Referential metadatas' do
              is_expected.to all(have_attributes(created_at: original_timestamp))
            end
          end
        end

        context 'when the merged Referential already exists' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line1
              line :line2
              referential :source, lines: [:line1]

              referential :new, lines: [:line2], archived_at: Time.now
            end
          end
          let(:merge) { merge_context.merge }
          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          describe 'the merged Referential metadatas' do
            it 'describe the lines x periods provided by source and existing metadatas (simple case)' do
              original_line_periods = new.metadatas.line_periods

              merge.merge!

              expect(merge.new.metadatas.line_periods).to eq(original_line_periods.merge(source.metadatas.line_periods))
            end

            it 'keep unchanged referential_source_id for existing metadatas' do
              new.metadatas.update_all referential_source_id: 42

              merge.merge!

              existing_metadatas = merge.new.metadatas.where(line_ids: new.metadatas.first.line_ids)
              expect(existing_metadatas).to all(have_attributes(referential_source_id: 42))
            end

            it 'use the source referential as referential_source_id for new metadatas' do
              merge.merge!

              new_metadatas = merge.new.metadatas.where.not(line_ids: new.metadatas.first.line_ids)
              expect(new_metadatas).to all(have_attributes(referential_source_id: source.id))
            end

            it 'should keep the created_at timestamp of source Referential metadatas' do
              original_timestamp = Time.now.beginning_of_day
              new.metadatas.update_all created_at: original_timestamp

              merge.merge!

              existing_metadatas = merge.new.metadatas.where(line_ids: new.metadatas.first.line_ids)
              expect(existing_metadatas).to all(have_attributes(created_at: original_timestamp))
            end
          end
        end
      end

      describe 'Route merge' do
        context 'when no Route with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          it 'creates a Route in the merged data set' do
            merge.merge!

            merge.new.switch do
              expect(Chouette::Route.count).to be(1)
            end
          end
        end

        context 'when a Route with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              workbench do
                stop_area :first
                stop_area :second
                stop_area :third

                line :line

                referential :source, lines: [:line] do
                  time_table :default

                  route :source_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third

                    vehicle_journey time_tables: [:default]
                  end
                end

                referential :new, lines: [:line], archived_at: Time.now do
                  route :existing_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third
                  end
                end
              end
            end
          end

          let(:new) { merge_context.new }
          let(:merge) { merge_context.merge }

          let(:existing_route) { merge_context.existing_route }
          let(:source_route) { merge_context.source_route }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
            end
          end

          it "doesn't create a new Route" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::Route.find(existing_route.id)).to be_present
              expect(Chouette::Route.count).to be(1)
            end
          end
        end

        context 'when the Route has an invalid checksum' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route :source_route, line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          before do
            merge_context.source.switch do
              merge_context.source.routes.update_all checksum: 'invalid'
            end
          end

          it 'creates a Route in the merged data set with a valid checksum' do
            merge.merge!

            merge.new.switch do
              expect(Chouette::Route.count).to be(1)

              expect { Chouette::ChecksumUpdater.new(merge.new).update }.to_not(change do
                Chouette::Route.pluck :checksum
              end)
            end
          end
        end
      end

      describe 'JourneyPattern merge' do
        context 'when no JourneyPattern with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          it 'creates a JourneyPattern in the merged data set' do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end
        end

        context 'when a JourneyPattern with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              workbench do
                stop_area :first
                stop_area :second
                stop_area :third

                line :line

                referential :source, lines: [:line] do
                  time_table :default

                  route :source_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third

                    journey_pattern :source_journey_pattern do
                      vehicle_journey time_tables: [:default]
                    end
                  end
                end

                referential :new, lines: [:line], archived_at: Time.now do
                  route :existing_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third

                    journey_pattern :existing_journey_pattern
                  end
                end
              end
            end
          end

          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          let(:merge) { merge_context.merge }

          let(:source_route) { merge_context.source_route }
          let(:existing_route) { merge_context.existing_route }

          let(:source_journey_pattern) { merge_context.source_journey_pattern }
          let(:existing_journey_pattern) { merge_context.existing_journey_pattern }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
              existing_journey_pattern.reload.update_column :checksum, source_journey_pattern.checksum
            end
          end

          it "doesn't create a new JourneyPattern" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.find(existing_journey_pattern.id)).to be_present
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end
        end

        context "when the existing Route hasn't the same position absolute values" do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              workbench do
                line :line

                stop_area :first
                stop_area :second
                stop_area :third

                referential :source, lines: [:line] do
                  time_table :default

                  route :source_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third

                    journey_pattern :merged do
                      vehicle_journey time_tables: [:default]
                    end
                  end
                end

                referential :new, lines: [:line], archived_at: Time.now do
                  route :existing_route, line: :line, with_stops: false do
                    stop_point stop_area: :first, position: 20
                    stop_point stop_area: :second, position: 30
                    stop_point stop_area: :third, position: 40
                  end
                end
              end
            end
          end

          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          let(:source_route) { merge_context.source_route }
          let(:existing_route) { merge_context.existing_route }

          let(:merge) { merge_context.merge }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
            end
          end

          it 'create a new JourneyPattern' do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end
        end
      end

      describe 'VehicleJourney merge' do
        context 'when no VehicleJourney with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          it 'creates a VehicleJourney in the merged data set' do
            merge.merge!

            merge.new.switch do
              expect(Chouette::VehicleJourney.count).to be(1)
            end
          end
        end

        context 'when a VehicleJourney with the same checksum already exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              workbench do
                line :line
                line :alternative_line

                stop_area :first
                stop_area :second
                stop_area :third

                referential :source, lines: [:line] do
                  time_table :source_time_table
                  route :source_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third
                    journey_pattern :source_journey_pattern do
                      vehicle_journey :source_vehicle_journey, time_tables: [:source_time_table]
                    end
                  end
                end

                referential :new, lines: %i[line alternative_line], archived_at: Time.zone.now do
                  time_table :existing_time_table
                  route :existing_route, line: :line, with_stops: false do
                    stop_point stop_area: :first
                    stop_point stop_area: :second
                    stop_point stop_area: :third
                    journey_pattern :existing_journey_pattern do
                      vehicle_journey :existing_vehicle_journey, time_tables: [:existing_time_table]
                    end
                  end
                end
              end
            end
          end

          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          let(:merge) { merge_context.merge }

          let(:existing_route_checksum) { merge_context.source_route.checksum }
          let(:existing_journey_pattern_checksum) { merge_context.source_journey_pattern.checksum }
          let(:existing_vehicle_journey_checksum) { merge_context.source_vehicle_journey.checksum }

          before do
            new.switch do
              merge_context.existing_route.update_column :checksum, existing_route_checksum
              merge_context.existing_journey_pattern.update_column :checksum, existing_journey_pattern_checksum
              merge_context.existing_vehicle_journey.update_column :checksum, existing_vehicle_journey_checksum
            end
          end

          context "when the JourneyPattern doesn't have the same checksum" do
            let(:existing_journey_pattern_checksum) { 'other' }

            it 'creates a VehicleJourney in the merged data set' do
              existing_vehicle_journey = merge_context.existing_vehicle_journey
              merge.merge!

              merge.new.switch do
                expect(existing_vehicle_journey).to_not exist_in_database
                expect(Chouette::VehicleJourney.find_by(checksum: merge_context.source_vehicle_journey.checksum)).to be_present
              end
            end
          end

          context "when the Route doesn't have the same checksum" do
            let(:existing_route_checksum) { 'other' }

            it 'creates a VehicleJourney in the merged data set' do
              existing_vehicle_journey = merge_context.existing_vehicle_journey
              merge.merge!

              merge.new.switch do
                expect(existing_vehicle_journey).to_not exist_in_database
                expect(Chouette::VehicleJourney.find_by(checksum: merge_context.source_vehicle_journey.checksum)).to be_present
              end
            end
          end

          context "when the Route doesn't have the same line" do
            let(:alternative_line) { merge_context.context.line :alternative_line }

            before do
              new.switch do
                merge_context.existing_route.update_column :line_id, alternative_line.id
              end
            end

            it 'creates a VehicleJourney in the merged data set' do
              existing_vehicle_journey = merge_context.existing_vehicle_journey
              merge.merge!

              merge.new.switch do
                expect(existing_vehicle_journey).to_not exist_in_database
                expect(Chouette::VehicleJourney.find_by(checksum: merge_context.source_vehicle_journey.checksum)).to be_present
              end
            end
          end

          it "doesn't create a new VehicleJourney" do
            existing_vehicle_journey = merge_context.existing_vehicle_journey

            merge.merge!

            merge.new.switch do
              expect(existing_vehicle_journey).to exist_in_database
              expect(Chouette::VehicleJourney.count).to eq(1)
            end
          end
        end
      end

      describe 'VehicleJourney Codes merge' do
        context 'when no such code exists in the merged data set (on the same Vehicle Journey)' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              code_space short_name: 'test'

              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default], codes: { test: 'value' }
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          it 'creates the VehicleJourney code in the merged data set' do
            merge.merge!

            merge.new.switch do
              vehicle_journey = merge.new.vehicle_journeys.sole
              expected_code = an_object_having_attributes(
                value: 'value',
                code_space: an_object_having_attributes(short_name: 'test')
              )
              expect(vehicle_journey.codes).to contain_exactly(expected_code)
            end
          end
        end

        context 'when the merged Vehicle Journey exists but without code' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              code_space short_name: 'test'

              stop_area :first
              stop_area :second
              stop_area :third

              line :line

              referential :source, lines: [:line] do
                time_table :source_time_table
                route :source_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third
                  journey_pattern :source_journey_pattern do
                    vehicle_journey :source_vehicle_journey, time_tables: [:source_time_table], codes: { test: 'value' }
                  end
                end
              end

              referential :new, lines: [:line], archived_at: Time.now do
                time_table :existing_time_table
                route :existing_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third
                  journey_pattern :existing_journey_pattern do
                    vehicle_journey :existing_vehicle_journey, time_tables: [:existing_time_table]
                  end
                end
              end
            end
          end

          let(:existing_route_checksum) { merge_context.source_route.checksum }
          let(:existing_journey_pattern_checksum) { merge_context.source_journey_pattern.checksum }
          let(:existing_vehicle_journey_checksum) { merge_context.source_vehicle_journey.checksum }

          before do
            merge_context.new.switch do
              merge_context.existing_route.update_column :checksum, existing_route_checksum
              merge_context.existing_journey_pattern.update_column :checksum, existing_journey_pattern_checksum
              merge_context.existing_vehicle_journey.update_column :checksum, existing_vehicle_journey_checksum
            end
          end

          let(:merge) { merge_context.merge }

          it 'creates the VehicleJourney code in the merged data set' do
            merge.merge!

            merge.new.switch do
              vehicle_journey = merge.new.vehicle_journeys.sole
              expected_code = an_object_having_attributes(
                value: 'value',
                code_space: an_object_having_attributes(short_name: 'test')
              )
              expect(vehicle_journey.codes).to contain_exactly(expected_code)
            end
          end
        end

        context 'when the same code (code space / value) exists in the merged data set' do
          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              code_space short_name: 'test'

              stop_area :first
              stop_area :second
              stop_area :third

              line :line

              referential :source, lines: [:line] do
                time_table :source_time_table
                route :source_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third
                  journey_pattern :source_journey_pattern do
                    vehicle_journey :source_vehicle_journey, time_tables: [:source_time_table], codes: { test: 'value' }
                  end
                end
              end

              referential :new, lines: [:line], archived_at: Time.now do
                time_table :existing_time_table
                route :existing_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third
                  journey_pattern :existing_journey_pattern do
                    vehicle_journey :existing_vehicle_journey, time_tables: [:existing_time_table],
                                                               codes: { test: 'value' }
                  end
                end
              end
            end
          end

          let(:existing_route_checksum) { merge_context.source_route.checksum }
          let(:existing_journey_pattern_checksum) { merge_context.source_journey_pattern.checksum }
          let(:existing_vehicle_journey_checksum) { merge_context.source_vehicle_journey.checksum }

          before do
            merge_context.new.switch do
              merge_context.existing_route.update_column :checksum, existing_route_checksum
              merge_context.existing_journey_pattern.update_column :checksum, existing_journey_pattern_checksum
              merge_context.existing_vehicle_journey.update_column :checksum, existing_vehicle_journey_checksum
            end
          end

          let(:merge) { merge_context.merge }

          it 'keeps existing VehicleJourney code in the merged data set' do
            merge.merge!

            merge.new.switch do
              vehicle_journey = merge.new.vehicle_journeys.sole
              expected_code = an_object_having_attributes(
                value: 'value',
                code_space: an_object_having_attributes(short_name: 'test')
              )
              expect(vehicle_journey.codes).to contain_exactly(expected_code)
            end
          end
        end
      end

      context 'when a code with same code space exists in the merged data set' do
        let(:merge_context) do
          MergeContext.new(merge_method: merge_method) do
            code_space short_name: 'test'

            stop_area :first
            stop_area :second
            stop_area :third

            line :line

            referential :source, lines: [:line] do
              time_table :source_time_table
              route :source_route, line: :line, with_stops: false do
                stop_point stop_area: :first
                stop_point stop_area: :second
                stop_point stop_area: :third
                journey_pattern :source_journey_pattern do
                  vehicle_journey :source_vehicle_journey, time_tables: [:source_time_table], codes: { test: 'new' }
                end
              end
            end

            referential :new, lines: [:line], archived_at: Time.now do
              time_table :existing_time_table
              route :existing_route, line: :line, with_stops: false do
                stop_point stop_area: :first
                stop_point stop_area: :second
                stop_point stop_area: :third
                journey_pattern :existing_journey_pattern do
                  vehicle_journey :existing_vehicle_journey, time_tables: [:existing_time_table], codes: { test: 'old' }
                end
              end
            end
          end
        end

        let(:existing_route_checksum) { merge_context.source_route.checksum }
        let(:existing_journey_pattern_checksum) { merge_context.source_journey_pattern.checksum }
        let(:existing_vehicle_journey_checksum) { merge_context.source_vehicle_journey.checksum }

        before do
          merge_context.new.switch do
            merge_context.existing_route.update_column :checksum, existing_route_checksum
            merge_context.existing_journey_pattern.update_column :checksum, existing_journey_pattern_checksum
            merge_context.existing_vehicle_journey.update_column :checksum, existing_vehicle_journey_checksum
          end
        end

        let(:merge) { merge_context.merge }

        it 'creates new VehicleJourney code and keep old one in the merged data set' do
          merge.merge!

          merge.new.switch do
            vehicle_journey = merge.new.vehicle_journeys.sole
            expected_codes = %w[old new].map do |value|
              an_object_having_attributes(
                value: value,
                code_space: an_object_having_attributes(short_name: 'test')
              )
            end
            expect(vehicle_journey.codes).to match_array(expected_codes)
          end
        end
      end
    end
  end
end
