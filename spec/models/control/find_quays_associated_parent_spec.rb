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

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:line) { context.line(:line) }
    let(:lexical_distance) { 0 }
    let(:geographical_distance) { 50 }

    before do
      referential.switch
    end

    describe 'Transport Mode' do
      let(:first_in_first_cluster) { context.stop_area(:first_in_first_cluster) }
      let(:second_in_first_cluster) { context.stop_area(:second_in_first_cluster) }

      let(:expected_messages) do
        [
          an_object_having_attributes({
                                      source: first_in_first_cluster,
                                      criticity: 'warning',
                                      message_attributes: {
                                        'stop_area_name' => 'In cluster I',
                                        'cluster_id' => 0,
                                        'short_id' => first_in_first_cluster.get_objectid.short_id
                                      }
                                    }),
        an_object_having_attributes({
                                      source: second_in_first_cluster,
                                      criticity: 'warning',
                                      message_attributes: {
                                        'stop_area_name' => 'In cluster II',
                                        'cluster_id' => 0,
                                        'short_id' => second_in_first_cluster.get_objectid.short_id
                                      }
                                    })
        ]
      end

      let(:context) do
        Chouette.create do
          workbench do
            line :first_line, name: 'Line', transport_mode: 'bus'

            stop_area :first_in_first_cluster, name: 'In cluster I', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
            stop_area :second_in_first_cluster, name: 'In cluster II', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
            stop_area :third_not_in_first_cluster, name: 'In cluster II', transport_mode: 'tramway', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'

            referential do
              route(line: :first_line, stop_areas: %i[first_in_first_cluster second_in_first_cluster third_not_in_first_cluster]) do
                journey_pattern :journey_pattern
              end
            end
          end
        end
      end

      it 'should detect potential grouped Stop Area' do
        control_run.run

        expect(control_run.control_messages).to match_array(expected_messages)
      end
    end

    describe 'Lexical distance' do
      let(:first) { context.stop_area(:first) }
      let(:second) { context.stop_area(:second) }

      context 'When similarity is required to be exactly the same' do
        let(:lexical_distance) { 100 }

        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              stop_area :first, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :second, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :other, name: 'Other', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first second other]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        let(:expected_messages) do
          [
            an_object_having_attributes({
                                        source: first,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Sample',
                                          'cluster_id' => 0,
                                          'short_id' => first.get_objectid.short_id
                                        }
                                      }),
          an_object_having_attributes({
                                        source: second,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Sample',
                                          'cluster_id' => 0,
                                          'short_id' => second.get_objectid.short_id
                                        }
                                      })
          ]
        end

        it 'should contain first and second in the same cluster and not contain other' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end

      context 'when similarity is required about 60%' do
        let(:lexical_distance) { 60 }

        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              stop_area :first, name: 'Sample 1', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :second, name: 'Sample 2', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :other, name: 'Other', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first second other]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        let(:expected_messages) do
          [
            an_object_having_attributes({
                                        source: first,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Sample 1',
                                          'cluster_id' => 0,
                                          'short_id' => first.get_objectid.short_id
                                        }
                                      }),
          an_object_having_attributes({
                                        source: second,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Sample 2',
                                          'cluster_id' => 0,
                                          'short_id' => second.get_objectid.short_id
                                        }
                                      })
          ]
        end

        it 'should contain first and second in the same cluster and not contain other' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end

      context 'when similarity is not required' do
        let(:lexical_distance) { 0 }

        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              stop_area :first, name: 'First sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :second, name: 'Second sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
              stop_area :other, name: 'Other', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first second other]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        let(:other) { context.stop_area(:other) }

        let(:expected_messages) do
          [
            an_object_having_attributes({
                                        source: first,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'First sample',
                                          'cluster_id' => 0,
                                          'short_id' => first.get_objectid.short_id
                                        }
                                      }),
          an_object_having_attributes({
                                        source: second,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Second sample',
                                          'cluster_id' => 0,
                                          'short_id' => second.get_objectid.short_id
                                        }
                                      }),
          an_object_having_attributes({
                                        source: other,
                                        criticity: 'warning',
                                        message_attributes: {
                                          'stop_area_name' => 'Other',
                                          'cluster_id' => 0,
                                          'short_id' => other.get_objectid.short_id
                                        }
                                      })
          ]
        end

        it 'should contain first, second and other in the same cluster' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end
    end

    describe 'Geographical distance' do
      context 'case simple' do
        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              # thhe geographical distance is about 66 meters in google maps
              stop_area :first, name: 'Sample', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :second, name: 'Sample', transport_mode: 'bus', longitude: -1.536850, latitude: 47.215037, area_type: 'zdep'

              referential do
                route(line: :first_line, stop_areas: %i[first second]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end
        let(:first) { context.stop_area(:first) }
        let(:second) { context.stop_area(:second) }

        context 'when the control uses geographical distance of 100 meters' do
          let(:geographical_distance) { 100}

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: second,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => second.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should contain first and second in the same cluster' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end

        context 'when the control uses geographical distance of 50 meters' do
          let(:geographical_distance) { 50 }

          it 'should not find any clusters' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end
      end

      context 'case complex' do
        let(:context) do
          Chouette.create do
            workbench do
              line :first_line, name: 'Line', transport_mode: 'bus'

              # thhe geographical distance is about 66 meters in google maps
              stop_area :first, name: 'Sample', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :second, name: 'Sample', transport_mode: 'bus', longitude: -1.536850, latitude: 47.215037, area_type: 'zdep'

              # the geographical distance is about 86 meters in google maps
              stop_area :third, name: 'Sample', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :fourth, name: 'Sample', transport_mode: 'bus', longitude: -1.535978, latitude: 47.211809, area_type: 'zdep'

              # The distance between the two points you provided is approximately 280 meters
              # Both locations are situated in Nantes, France. Here are the details for your route:
              # Point A: 47.214722, -1.537587 (Near 3 Rue Marcel Paul)
              # Point B: 47.212535, -1.536317 (Near 16 Allée Jacques Berque)

              # The distance between these two points in Nantes, France, is approximately 350 meters.
              # Here are the trip details for the coordinates provided:
              # Point A (Origin): 47.214722, -1.537587 (near 3 Rue Marcel Paul)
              # Point B (Destination): 47.211809, -1.535978 (near Pont Willy-Brandt)

              referential do
                route(line: :first_line, stop_areas: %i[first second third fourth]) do
                  journey_pattern :journey_pattern
                end
              end
            end
          end
        end

        let(:first) { context.stop_area(:first) }
        let(:second) { context.stop_area(:second) }
        let(:third) { context.stop_area(:third) }
        let(:fourth) { context.stop_area(:fourth) }

        context 'when the control uses geographical distance of 150 meters' do
          let(:geographical_distance) { 150}

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => first.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: second,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 0,
                                            'short_id' => second.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: third,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 1,
                                            'short_id' => third.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: fourth,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 1,
                                            'short_id' => fourth.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should two clusters with cluster 0 (first and second) and cluster 1 (third and fourth)' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end
      end
    end
  end
end


