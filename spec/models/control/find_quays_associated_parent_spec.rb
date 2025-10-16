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
        geographical_distance: 50,
        used_by_opposite_routes: false,
        lexical_distance: 0,
        criticity: 'warning',
        position: 0
      )
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:line) { context.line(:line) }

    let(:first_in_first_cluster) { context.stop_area(:first_in_first_cluster) }
    let(:second_in_first_cluster) { context.stop_area(:second_in_first_cluster) }

    let(:first_in_second_cluster) { context.stop_area(:first_in_second_cluster) }
    let(:second_in_second_cluster) { context.stop_area(:second_in_second_cluster) }
    let(:third_in_second_cluster) { context.stop_area(:third_in_second_cluster) }

    before do
      referential.switch
    end

    let(:context) do
      Chouette.create do
        workbench do
          line :first_line, name: 'Line', transport_mode: 'bus'

          stop_area :first_in_first_cluster, name: 'In cluster I', transport_mode: 'bus', longitude: 5.823483, latitude: 46.109425, area_type: 'zdep'
          stop_area :second_in_first_cluster, name: 'In cluster II', transport_mode: 'bus', longitude: 5.823480, latitude: 46.109426, area_type: 'zdep'

          stop_area :first_in_second_cluster, name: 'In cluster III', transport_mode: 'bus', longitude: 5.96136, latitude: 46.14473, area_type: 'zdep'
          stop_area :second_in_second_cluster, name: 'In cluster IV', transport_mode: 'bus', longitude: 5.96137, latitude: 46.14474, area_type: 'zdep'
          stop_area :third_in_second_cluster, name: 'In cluster V', transport_mode: 'bus', longitude: 5.96138, latitude: 46.14474, area_type: 'zdep'

          stop_area :first_not_in_cluster, transport_mode: 'tramway', longitude: 5.823480, latitude: 46.109426, area_type: 'zdep'
          stop_area :second_not_in_cluster, transport_mode: 'bus', longitude: 5.823480, latitude: 46.109426, area_type: 'lda'
          stop_area :third_not_in_cluster, transport_mode: 'bus', longitude: 5.023480, latitude: 42.109426, area_type: 'zdep'
          stop_area :fourth_not_in_second_cluster, name: ' In cluster III', transport_mode: 'tramway', longitude: 5.96138, latitude: 46.14474, area_type: 'zdep'

          referential do
            route(line: :first_line, stop_areas: %i[first_in_first_cluster second_not_in_cluster third_not_in_cluster]) do
              journey_pattern :journey_pattern
            end
          end
        end
      end
    end

    let(:expected_messages) do
      [
        an_object_having_attributes({
                                    source: first_in_first_cluster,
                                    criticity: 'warning',
                                    message_attributes: {
                                      'stop_area_name' => 'In cluster I',
                                      'cluster_id' => 0
                                    }
                                  }),
      an_object_having_attributes({
                                    source: second_in_first_cluster,
                                    criticity: 'warning',
                                    message_attributes: {
                                      'stop_area_name' => 'In cluster II',
                                      'cluster_id' => 0
                                    }
                                  }),
      an_object_having_attributes({
                                    source: first_in_second_cluster,
                                    criticity: 'warning',
                                    message_attributes: {
                                      'stop_area_name' => 'In cluster III',
                                      'cluster_id' => 1
                                    }
                                  }),
      an_object_having_attributes({
                                    source: second_in_second_cluster,
                                    criticity: 'warning',
                                    message_attributes: {
                                      'stop_area_name' => 'In cluster IV',
                                      'cluster_id' => 1
                                    }
                                  }),
      an_object_having_attributes({
                                    source: third_in_second_cluster,
                                    criticity: 'warning',
                                    message_attributes: {
                                      'stop_area_name' => 'In cluster V',
                                      'cluster_id' => 1
                                    }
                                  })
      ]
    end

    it 'should detect potential grouped Stop Area' do
      control_run.run

      expect(control_run.control_messages).to match_array(expected_messages)
    end
  end
end


