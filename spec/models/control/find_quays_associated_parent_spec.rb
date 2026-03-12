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

        context 'when transport mode is present' do
          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'First in route1',
                                            'cluster_id' => 'bus_4321_39515_0_0',
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'First in route2',
                                            'cluster_id' => 'bus_4321_39515_0_0',
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

        context 'when transport mode is not present' do
          let(:context) do
            Chouette.create do
              workbench do
                line :first_line, name: 'Line', transport_mode: 'bus'

                stop_area :first_in_route1, name: 'First in route1', transport_mode: nil, longitude: 5.823483, latitude: 46.909425, area_type: 'zdep'
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

          it 'should be not used to grouped Stop Area' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
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
                line :line, name: 'Line', transport_mode: 'bus'

                stop_area :first_in_route1, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :first_in_route2, name: 'Sample', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129426, area_type: 'zdep'
                stop_area :first_in_route3, name: 'Other', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129427, area_type: 'zdep'

                stop_area :extra, name: 'Extra', transport_mode: 'bus', longitude: 5.8, latitude: 46.2, area_type: 'zdep'

                referential do
                  route(line: :line, stop_areas: %i[first_in_route1 extra])
                  route(line: :line, stop_areas: %i[first_in_route2 extra])
                  route(line: :line, stop_areas: %i[first_in_route3 extra])
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
                                            'cluster_id' => 'bus_4321_38674_0_0',
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 'bus_4321_38674_0_0',
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
                line :line, name: 'Line', transport_mode: 'bus'

                stop_area :first_in_route1, name: 'Gare de Lyon', transport_mode: 'bus', longitude: 5.823483, latitude: 46.129425, area_type: 'zdep'
                stop_area :first_in_route2, name: 'Gare Lyon', transport_mode: 'bus', longitude: 5.823484, latitude: 46.129426, area_type: 'zdep'
                stop_area :first_in_route3, name: 'Other', transport_mode: 'bus', longitude: 5.823484, latitude: 46.129426, area_type: 'zdep'

                stop_area :extra, name: 'Extra', transport_mode: 'bus', longitude: 5.9, latitude: 46.2, area_type: 'zdep'

                referential do
                  route(line: :line, stop_areas: %i[first_in_route1 extra])
                  route(line: :line, stop_areas: %i[first_in_route2 extra])
                  route(line: :line, stop_areas: %i[first_in_route3 extra])
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
                                            'stop_area_name' => 'Gare de Lyon',
                                            'cluster_id' => 'bus_4321_38674_0_0',
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Gare Lyon',
                                            'cluster_id' => 'bus_4321_38674_0_0',
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
              line :line, name: 'Line', transport_mode: 'bus'

              # Distance 66m from first_in_route1 to first_in_route2
              stop_area :first_in_route1, name: 'Sample', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :first_in_route2, name: 'Sample', transport_mode: 'bus', longitude: -1.536850, latitude: 47.215037, area_type: 'zdep'

              # Distance about 280m from first_in_route2 to second_in_route3 and about 260m from first_in_route1 to second_in_route3
              stop_area :first_in_route3, name: 'Sample', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'

              stop_area :extra, name: 'Extra', transport_mode: 'bus', longitude: -1.5, latitude: 47.2, area_type: 'zdep'

              referential do
                route(line: :line, stop_areas: %i[first_in_route1 extra])
                route(line: :line, stop_areas: %i[first_in_route2 extra])
                route(line: :line, stop_areas: %i[first_in_route3 extra])
              end
            end
          end
        end

        let(:first_in_route1) { context.stop_area(:first_in_route1) }
        let(:first_in_route2) { context.stop_area(:first_in_route2) }

        context 'when the control uses geographical distance of 150 meters' do
          let(:geographical_distance) { 150 }

          let(:expected_messages) do
            [
              an_object_having_attributes({
                                          source: first_in_route1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 'bus_-381_13282_0_0',
                                            'short_id' => first_in_route1.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: first_in_route2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'Sample',
                                            'cluster_id' => 'bus_-381_13282_0_0',
                                            'short_id' => first_in_route2.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should contain first_in_route1 and first_in_route2 in the same cluster' do
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

              stop_area :ar1, name: 'A R1', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'
              stop_area :br1, name: 'B R1', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'

              stop_area :br2, name: 'B R2', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :ar2, name: 'A R2', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'

              stop_area :ar3, name: 'A R3', transport_mode: 'bus', longitude: -1.536317, latitude: 47.212535, area_type: 'zdep'
              stop_area :br3, name: 'B R3', transport_mode: 'bus', longitude: -1.537587, latitude: 47.214722, area_type: 'zdep'

              referential do
                route(:route, line: :first_line, stop_areas: %i[ar1 br1])
                route(:opposite_route, line: :first_line, stop_areas: %i[br2 ar2])

                route(:other_route, line: :second_line, stop_areas: %i[ar3 br3])
              end
            end
          end
        end

        let(:source) { context.referential }
        let(:route) { context.route(:route) }
        let(:opposite_route) { context.route(:opposite_route) }

        let(:ar1) { context.stop_area(:ar1) }
        let(:br1) { context.stop_area(:br1) }
        let(:br2) { context.stop_area(:br2) }
        let(:ar2) { context.stop_area(:ar2) }

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
                                          source: ar1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'A R1',
                                            'cluster_id' => 'bus_-381_13282_0_0',
                                            'short_id' => ar1.get_objectid.short_id
                                          }
                                        }),
            an_object_having_attributes({
                                          source: br1,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'B R1',
                                            'cluster_id' => 'bus_-381_13281_1_0',
                                            'short_id' => br1.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: br2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'B R2',
                                            'cluster_id' => 'bus_-381_13281_1_0',
                                            'short_id' => br2.get_objectid.short_id
                                          }
                                        }),
              an_object_having_attributes({
                                          source: ar2,
                                          criticity: 'warning',
                                          message_attributes: {
                                            'stop_area_name' => 'A R2',
                                            'cluster_id' => 'bus_-381_13282_0_0',
                                            'short_id' => ar2.get_objectid.short_id
                                          }
                                        })
            ]
          end

          it 'should two clusters with cluster bus_-381_13282_0_0 (ar1 and ar2) and cluster bus_-381_13281_1_0 (br1 and br2)' do
            control_run.run

            expect(control_run.control_messages).to match_array(expected_messages)
          end
        end

      end

      describe 'Geographical distance clustering with multiple clusters' do
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
              stop_area :orly_1, name: 'Orly 1-2-3', longitude: 2.3595536, latitude: 48.72956086, area_type: 'zdep', transport_mode: 'bus'
              stop_area :orly_2, name: 'Orly 1-2-3', longitude: 2.35952663, latitude: 48.72954272, area_type: 'zdep', transport_mode: 'bus'

              # cluster Bel-Air (Distance 0m)
              stop_area :ba_1, name: 'Bel-Air', longitude: 2.40086713, latitude: 48.84142733, area_type: 'zdep', transport_mode: 'bus'
              stop_area :ba_2, name: 'Bel-Air', longitude: 2.40086713, latitude: 48.84142733, area_type: 'zdep', transport_mode: 'bus'

              # cluster Anna de Noailles (Distance ~30m)
              stop_area :an_1, name: 'Anna de Noailles', longitude: 2.27791812, latitude: 48.87441132, area_type: 'zdep', transport_mode: 'bus'
              stop_area :an_2, name: 'Anna de Noailles', longitude: 2.27816464, latitude: 48.87433186, area_type: 'zdep', transport_mode: 'bus'

              # extra stop to ensure each route has at least 2 stop areas
              stop_area :extra, name: 'Extra Stop', longitude: 2.5, latitude: 48.9, area_type: 'zdep', transport_mode: 'bus'

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
              message_attributes: hash_including({ 'stop_area_name' => 'Orly 1-2-3', 'cluster_id' => 'bus_1751_41527_0_0' })
            }),
            an_object_having_attributes({
              source: orly_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Orly 1-2-3', 'cluster_id' => 'bus_1751_41527_0_0' })
            }),

            # Cluster 1: Bel-Air group
            an_object_having_attributes({
              source: ba_1,
              message_attributes: hash_including({ 'stop_area_name' => 'Bel-Air', 'cluster_id' => 'bus_1781_41653_1_0' })
            }),
            an_object_having_attributes({
              source: ba_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Bel-Air', 'cluster_id' => 'bus_1781_41653_1_0' })
            }),

            # Cluster 2: Anna group
            an_object_having_attributes({
              source: an_1,
              message_attributes: hash_including({ 'stop_area_name' => 'Anna de Noailles', 'cluster_id' => 'bus_1690_41690_2_0' })
            }),
            an_object_having_attributes({
              source: an_2,
              message_attributes: hash_including({ 'stop_area_name' => 'Anna de Noailles', 'cluster_id' => 'bus_1690_41690_2_0' })
            })
          ]
        end

        it 'should identify 3 distinct clusters' do
          control_run.run

          expect(control_run.control_messages).to match_array(expected_messages)
        end
      end

      describe 'Avoid chaining effect' do
        let(:context) do
          Chouette.create do
            workbench do
              # Create 47 lines (0 to 46)
              (0..46).each do |i|
                line "l#{i}".to_sym, name: "Chain Link #{i}"
              end

              # Starting position: Orly area
              # Root point
              stop_area :orly, name: 'Orly Start', longitude: 2.3590, latitude: 48.7290, area_type: 'zdep'

              # Intermediate points: 45 links
              # Each step is approx 0.0006 degrees latitude (~66 meters)
              # Total distance covered: 45 * 66m = ~2,970 meters
              (1..45).each do |i|
                stop_area "bridge_#{i}".to_sym,
                          name: "Chain Link #{i}",
                          longitude: 2.3590,
                          latitude: 48.7290 + (i * 0.0006),
                          area_type: 'zdep'
              end

              # Final point (The 'Far Away' target at ~3km)
              stop_area :far_away, name: 'Bel-Air End',
                        longitude: 2.3590,
                        latitude: 48.7556,
                        area_type: 'zdep'

              # Dummy node to satisfy Route stop requirements (min 2 stops)
              stop_area :extra_node, name: 'Extra Node', longitude: 2.5000, latitude: 49.0000, area_type: 'zdep'

              referential do
                route line: :l0, stop_areas: %i[orly extra_node]

                (1..45).each do |i|
                  route line: "l#{i}".to_sym, stop_areas: ["bridge_#{i}".to_sym, :extra_node]
                end

                route line: :l46, stop_areas: %i[far_away extra_node]
              end
            end
          end
        end

        context 'when geographical_distance is 150' do
          let(:geographical_distance) { 100 }

          it 'should not create chaining effect from Orly Start to Bel-Air End' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end

        context 'when geographical_distance is 500' do
          let(:geographical_distance) { 500 }

          it 'should not create chaining effect from Orly Start to Bel-Air End' do
            control_run.run

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end
  end
end

RSpec.describe Control::FindQuaysAssociatedParent::Run::StopNameClustering::RougeSU do
  let(:calculator) { described_class.new(window_size: 4) }

  describe '#similarity' do
    context 'with identical strings' do
      it 'returns 1.0' do
        expect(calculator.similarity("Paris Gare de l'Est", "Paris Gare de l'Est")).to eq(1.0)
      end
    end

    context 'with completely different strings' do
      it 'returns 0.0' do
        expect(calculator.similarity('Paris', 'London')).to eq(0.0)
      end
    end

    context 'with different word orders' do
      it 'penalizes reversed order while keeping unigram matches' do
        s1 = 'Central Bus Station'
        s2 = 'Central Bus Station'
        s3 = 'Station Bus Central'

        score_normal = calculator.similarity(s1, s2)
        score_reversed = calculator.similarity(s1, s3)

        # s3 has same unigrams but lacks skip-bigrams like (Central, Bus)
        expect(score_normal).to be > score_reversed
      end
    end

    context 'with optional/filler words (The Skip-bigram power)' do
      it 'remains highly similar when words are inserted in between' do
        s1 = 'Paris Bus Station'
        s2 = 'Paris Central Bus Station' # 'Central' is inserted

        score = calculator.similarity(s1, s2)
        # Even with 'Central', skip-bigrams like (Paris, Bus) are preserved
        expect(score).to be > 0.7
      end
    end

    context 'with edge cases' do
      it 'handles nil or empty strings gracefully' do
        expect(calculator.similarity(nil, '')).to eq(0.0)
      end

      it 'ignores special characters and extra spaces' do
        expect(calculator.similarity('Bus!!!', '  bus  ')).to eq(1.0)
      end
    end
  end
end

RSpec.describe Control::FindQuaysAssociatedParent::Run::StopNameClustering do
  describe '#perform' do
    let(:threshold) { 0.5 }

    context 'when processing Paris major stations' do
      let(:names) do
        [
          'Paris Gare du Nord',
          'Gare du Nord',

          'Paris Gare de Lyon',
          'Gare de Lyon',
        ]
      end

      it "separates 'Nord' and 'Lyon' into two distinct clusters" do
        service = described_class.new(names, threshold: threshold)
        clusters = service.perform

        expect(clusters.size).to eq(2)

        nord_cluster = clusters.find { |c| c.include?('Paris Gare du Nord') }
        expect(nord_cluster).to include('Gare du Nord')
        expect(nord_cluster).not_to include('Paris Gare de Lyon')

        lyon_cluster = clusters.find { |c| c.include?('Paris Gare de Lyon') }
        expect(lyon_cluster).to include('Gare de Lyon')
        expect(lyon_cluster).not_to include('Paris Gare du Nord')
      end
    end

    context 'with similar prefixes but different cities' do
      let(:names) do
        [
          'Gare de Bordeaux Saint-Jean',
          'Gare de Strasbourg',
          'Gare de Lille Flandres'
        ]
      end

      it "does not cluster them despite sharing 'Gare de'" do
        service = described_class.new(names, threshold: threshold)
        clusters = service.perform

        # The unique city names should lower the ROUGE-SU score below 0.5
        expect(clusters.size).to eq(3)
      end
    end

    context 'handling regional variations' do
      let(:names) { ['Lyon Part-Dieu', 'Lyon P. Dieu', 'Gare de la Part-Dieu'] }

      it 'clusters variations of the same regional station' do
        service = described_class.new(names, threshold: 0.25)
        clusters = service.perform
        
        expect(clusters.size).to eq(1)
      end
    end

    context 'edge cases' do
      it 'returns empty array for empty input' do
        expect(described_class.new([]).perform).to eq([])
      end

      it 'return only one cluster when threshold is 0' do
        names = ['First', 'Second']
        service = described_class.new(names, threshold: 0)
        expect(service.perform.size).to eq(1)
      end 
    end
  end
end