# frozen_string_literal: true

RSpec.describe Control::FindQuaysAssociatedParent do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::FindQuaysAssociatedParent::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        geographical_distance: geographical_distance,
        used_by_opposite_routes: false,
        lexical_distance: lexical_distance,
        criticity: 'warning',
        position: 0
      )
    end

    let(:lexical_distance) { 0 }
    let(:geographical_distance) { 50 }

    context 'when there is no target referential in the control list' do
      let(:referential) { nil }
      let(:workbench) { nil }

      it 'should not create any messages' do
        control_run.run

        expect(control_run.control_messages).to be_empty
      end
    end

    context 'when there is target referential in the control list' do
      before { referential.switch }

      let(:workbench) { context.workbench }
      let(:referential) { context.referential }
      let(:line) { context.line(:line) }

      describe 'Transport Mode' do
        let(:first_in_route1) { context.stop_area(:first_in_route1) }
        let(:first_in_route2) { context.stop_area(:first_in_route2) }

        let(:expected_messages) do
          [
            an_object_having_attributes({
                                        source: first_in_route1,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'First in route1',
                                          'cluster_id' => 0,
                                          'short_id' => first_in_route1.get_objectid.short_id
                                        }
                                      }),
          an_object_having_attributes({
                                        source: first_in_route2,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'First in route2',
                                          'cluster_id' => 0,
                                          'short_id' => first_in_route2.get_objectid.short_id
                                        }
                                      })
          ]
        end

        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              stop_area :first_in_route1, name: 'First in route1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.909425, area_type: 'zdep'
              stop_area :second_in_route1, name: 'Second in route1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109435, area_type: 'zdep'

              stop_area :first_in_route2, name: 'First in route2', transport_mode: 'bus', longitude: 5.823483, latitude: 46.909425, area_type: 'zdep'
              stop_area :second_in_route2, name: 'Second in route2', transport_mode: 'tramway', longitude: 5.823483, latitude: 46.109435, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1]) do
                  journey_pattern :journey_pattern
                end

                route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        it 'should be used to grouped Stop Area' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end

      describe 'Lexical distance' do
        let(:first_in_route1) { context.stop_area(:first_in_route1) }
        let(:first_in_route2) { context.stop_area(:first_in_route2) }

        context 'when similarity is required to be exactly the same' do
          let(:lexical_distance) { 100 }

          let(:context) do
            Chouette.create do
              workbench do
                line :first_line, name: 'Line', transport_mode: 'bus'

                stop_area :first_in_route1, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :second_in_route1, name: 'Second in Route 1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129426, area_type: 'zdep'

                stop_area :first_in_route2, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :second_in_route2, name: 'Second in Route 2', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129426, area_type: 'zdep'

                referential do
                  route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1]) do
                    journey_pattern :journey_pattern
                  end

                  route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2]) do
                    journey_pattern :journey_pattern
                  end
                end
              end
            end
          end

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route2.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should contain first_in_route1 and first_in_route2 with exactly the same name in the same cluster' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end

        context 'when similarity is required about 50%' do
          let(:lexical_distance) { 50 }

          let(:first_in_route1) { context.stop_area(:first_in_route1) }
          let(:first_in_route2) { context.stop_area(:first_in_route2) }

          let(:context) do
            Chouette.create do
              workbench do
                line :first_line, name: 'Line', transport_mode: 'bus'

                stop_area :first_in_route1, name: 'Sample 1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :second_in_route1, name: 'Second in Route 1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129426, area_type: 'zdep'

                stop_area :first_in_route2, name: 'Sample 2', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :second_in_route2, name: 'Other', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129426, area_type: 'zdep'

                referential do
                  route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1]) do
                    journey_pattern :journey_pattern
                  end

                  route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2]) do
                    journey_pattern :journey_pattern
                  end
                end
              end
            end
          end

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample 1',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample 2',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route2.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should contain first_in_route1 and first_in_route2 with approximatively the same name in the same cluster' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end
      end

      describe 'Geographical distance' do
        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              # thhe geographical distance is about 66 meters in google maps
              stop_area :first_in_route1, name: 'Sample', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :first_in_route2, name: 'Sample', transport_mode: 'bus', longitude: -1.536850, latitude: 47.215037, area_type: 'zdep'

              # the geographical distance is about 86 meters in google maps
              stop_area :second_in_route1, name: 'Sample', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :second_in_route2, name: 'Sample', transport_mode: 'bus', longitude: -1.535978, latitude: 47.211809, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1]) do
                  journey_pattern :journey_pattern
                end

                route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        let(:first_in_route1) { context.stop_area(:first_in_route1) }
        let(:second_in_route1) { context.stop_area(:second_in_route1) }
        let(:first_in_route2) { context.stop_area(:first_in_route2) }
        let(:second_in_route2) { context.stop_area(:second_in_route2) }

        context 'when the control uses geographical distance of 150 meters' do
          let(:geographical_distance) { 150 }

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: second_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 1,
                                            'short_id' => second_in_route1.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route2.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: second_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 1,
                                            'short_id' => second_in_route2.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should two clusters with cluster 0 (first_in_route1 and first_in_route2) and cluster 1 (second_in_route1 and second_in_route2)' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end

        context 'when the control uses geographical distance of 50 meters' do
          let(:geographical_distance) { 50 }

          it 'should create any clusters' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end
  end
end
