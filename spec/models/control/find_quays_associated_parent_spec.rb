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
        used_by_opposite_routes: used_by_opposite_routes,
        lexical_distance: lexical_distance,
        criticity: 'warning',
        position: 0
      )
    end

    let(:lexical_distance) { 0 }
    let(:geographical_distance) { 50 }
    let(:used_by_opposite_routes) { false }

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
                route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1])
                route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2])
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
                route(line: :first_line, stop_areas: %i[first_in_route1 second_in_route1])
                route(line: :first_line, stop_areas: %i[first_in_route2 second_in_route2])
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

      describe 'Used by opposite route' do
        let(:used_by_opposite_routes) { true }

        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line 1', transport_mode: 'bus'
              line :second_line, name: 'Line 2', transport_mode: 'bus'

              stop_area :first_in_route1, name: 'A R1', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :second_in_route1, name: 'B R1', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'

              stop_area :first_in_route2, name: 'B R2', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :second_in_route2, name: 'A R2', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'

              stop_area :first_in_route3, name: 'A R3', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :second_in_route3, name: 'B R3', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'

              referential do
                route(:route, line: :first_line, stop_areas: %i[first_in_route1 second_in_route1])
                route(:opposite_route, line: :first_line, stop_areas: %i[first_in_route2 second_in_route2])

                route(:other_route, line: :second_line, stop_areas: %i[first_in_route3 second_in_route3])
              end
            end
          end
        end

        let(:source) { context.referential }
        let(:route) { context.route(:route) }
        let(:opposite_route) { context.route(:opposite_route) }

        let(:first_in_route1) { context.stop_area(:first_in_route1) }
        let(:second_in_route1) { context.stop_area(:second_in_route1) }
        let(:first_in_route2) { context.stop_area(:first_in_route2) }
        let(:second_in_route2) { context.stop_area(:second_in_route2) }

        before do
          source.switch do
            opposite_route.update wayback: route.opposite_wayback
            route.update opposite_route_id: opposite_route.id
          end
        end

        context 'when the control uses geographical distance of 150 meters' do
          let(:geographical_distance) { 150 }

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'A R1',
                                            'cluster_id' => 0,
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: second_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'B R1',
                                            'cluster_id' => 1,
                                            'short_id' => second_in_route1.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'B R2',
                                            'cluster_id' => 1,
                                            'short_id' => first_in_route2.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: second_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'A R2',
                                            'cluster_id' => 0,
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

      end

      describe 'Geographical distance clustering with clusters (Orly, Bel-Air, Anna)' do
        let(:orly_1) { context.stop_area(:orly_1) }
        let(:orly_2) { context.stop_area(:orly_2) }
        let(:ba_1) { context.stop_area(:ba_1) }
        let(:ba_2) { context.stop_area(:ba_2) }
        let(:an_1) { context.stop_area(:an_1) }
        let(:an_2) { context.stop_area(:an_2) }

        let(:context) do
          Chouette.create do
            workbench do
              line :l_orly, name: 'Orly Line', transport_mode: 'bus'
              line :l_belair, name: 'Bel-Air Line', transport_mode: 'bus'
              line :l_anna, name: 'Anna Line', transport_mode: 'bus'

              # Cluster Orly 1-2-3 (Distance ~3m)
              stop_area :orly_1, id: 675326, name: 'Orly 1-2-3', longitude: 2.3595536, latitude: 48.72956086, area_type: 'zdep'
              stop_area :orly_2, id: 675327, name: 'Orly 1-2-3', longitude: 2.35952663, latitude: 48.72954272, area_type: 'zdep'

              # cluster Bel-Air (Distance 0m)
              stop_area :ba_1, id: 682842, name: 'Bel-Air', longitude: 2.40086713, latitude: 48.84142733, area_type: 'zdep'
              stop_area :ba_2, id: 682473, name: 'Bel-Air', longitude: 2.40086713, latitude: 48.84142733, area_type: 'zdep'

              # cluster Anna de Noailles (Distance ~30m)
              stop_area :an_1, id: 8149568, name: 'Anna de Noailles', longitude: 2.27791812, latitude: 48.87441132, area_type: 'zdep'
              stop_area :an_2, id: 8149569, name: 'Anna de Noailles', longitude: 2.27816464, latitude: 48.87433186, area_type: 'zdep'

              # extra stop to ensure each route has at least 2 stop areas
              stop_area :extra, name: 'Extra Stop', longitude: 2.5, latitude: 48.9, area_type: 'zdep'

              referential do
                route line: :l_orly, stop_areas: %i[orly_1 extra]
                route line: :l_orly, stop_areas: %i[orly_2 extra]

                route line: :l_belair, stop_areas: %i[ba_1 extra]
                route line: :l_belair, stop_areas: %i[ba_2 extra]

                route line: :l_anna, stop_areas: %i[an_1 extra]
                route line: :l_anna, stop_areas: %i[an_2 extra]
              end
            end
          end
        end

        let(:expected_messages) do
          [
            # Cluster 0: Orly group
            an_object_having_attributes({
              source: orly_1,
              message_attributes: hash_including({ 'stop_area_name' => 'Orly 1-2-3', 'cluster_id' => 0 })
            }),
            an_object_having_attributes({
              source: orly_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Orly 1-2-3', 'cluster_id' => 0 })
            }),

            # Cluster 1: Bel-Air group
            an_object_having_attributes({
              source: ba_1,
              message_attributes: hash_including({ 'stop_area_name' => 'Bel-Air', 'cluster_id' => 1 })
            }),
            an_object_having_attributes({
              source: ba_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Bel-Air', 'cluster_id' => 1 })
            }),

            # Cluster 2: Anna group
            an_object_having_attributes({
              source: an_1,
              message_attributes: hash_including({ 'stop_area_name' => 'Anna de Noailles', 'cluster_id' => 2 })
            }),
            an_object_having_attributes({
              source: an_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Anna de Noailles', 'cluster_id' => 2 })
            })
          ]
        end

        it 'should identify 3 distinct clusters' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end
    end
  end
end
