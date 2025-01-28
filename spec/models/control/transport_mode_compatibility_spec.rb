# frozen_string_literal: true

RSpec.describe Control::TransportModeCompatibility do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::TransportModeCompatibility::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        position: 0
      )
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:line) { context.line(:line) }
    let(:first_correct_stop_area) { context.stop_area(:first_correct) }
    let(:second_correct_stop_area) { context.stop_area(:second_correct) }
    let(:wrong_stop_area) { context.stop_area(:wrong) }

    before do
      referential.switch
    end

    context 'when Line#transport_mode and StopArea#transport_mode are present' do
      let(:context) do
        Chouette.create do
          workbench do
            line :line, name: 'Line', transport_mode: 'bus'

            stop_area :first_correct, transport_mode: 'bus'
            stop_area :second_correct, transport_mode: 'bus'
            stop_area :wrong, name: 'Wrong', transport_mode: 'tramway'

            referential do
              route(line: :line, stop_areas: %i[first_correct second_correct wrong]) do
                journey_pattern
              end
            end
          end
        end
      end

      let(:expected_message) do
        an_object_having_attributes({
                                      source: wrong_stop_area,
                                      criticity: 'warning',
                                      message_attributes: {
                                        'stop_area_name' => 'Wrong',
                                        'line_name' => 'Line'
                                      }
                                    })
      end

      it 'should detect the faulty Stop Area' do
        control_run.run

        expect(control_run.control_messages).to include(expected_message)
      end
    end

    context 'when Line#transport_mode and StopArea#transport_mode are not present' do
      let(:context) do
        Chouette.create do
          workbench do
            line :line, name: 'Line', transport_mode: nil

            stop_area :first, transport_mode: nil
            stop_area :second, transport_mode: 'bus'
            stop_area :third, transport_mode: 'tramway'

            referential do
              route(line: :line, stop_areas: %i[first second third]) do
                journey_pattern
              end
            end
          end
        end
      end

      it 'should not detect first Stop Area' do
        control_run.run

        expect(control_run.control_messages).to be_empty
      end
    end
  end
end
