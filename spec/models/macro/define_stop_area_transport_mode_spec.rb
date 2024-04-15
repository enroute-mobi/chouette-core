# frozen_string_literal: true

RSpec.describe Macro::DefineStopAreaTransportMode do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::DefineStopAreaTransportMode::Run do
    let(:context) do
      Chouette.create do
        stop_area :first, transport_mode: 'bus'
        stop_area :second, transport_mode: nil
        stop_area :third, transport_mode: nil
        stop_area :last, transport_mode: nil

        line :line, transport_mode: 'bus', transport_submode: 'undefined'
        line :other, transport_mode: 'tram', transport_submode: 'undefined'

        referential do
          route line: :line, stop_areas: %i[first second last]
          route line: :other, stop_areas: %i[first third last]
        end
      end
    end

    let(:workgroup) { context.workgroup }
    let(:referential) { context.referential }
    let(:workbench) { referential.workbench }

    let(:second_stop_area) { context.stop_area(:second) }
    let(:third_stop_area) { context.stop_area(:third) }
    let(:first_stop_area) { context.stop_area(:first) }
    let(:last_stop_area) { context.stop_area(:last) }

    let(:macro_list_run) do
      Macro::List::Run.create workbench: workbench
    end

    subject(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0
      )
    end

    describe '.run' do
      subject { macro_run.run }

      before do
        referential.switch
      end

      context 'when the stop areas has no transport mode' do
        it 'should update transport_mode from line into second stop area' do
          expect do
            subject
            second_stop_area.reload
          end.to change { second_stop_area.transport_mode&.code }.from(nil).to('bus')
        end

        it 'should update transport_mode from other into third stop area' do
          expect do
            subject
            third_stop_area.reload
          end.to change { third_stop_area.transport_mode&.code }.to('tram')
        end

        it 'should not change transport_mode for the first stop area' do
          expect do
            subject
            first_stop_area.reload
          end.not_to(change { first_stop_area.transport_mode&.code })
        end

        it 'should not change transport_mode for the last stop area' do
          expect do
            subject
            last_stop_area.reload
          end.not_to(change { last_stop_area.transport_mode })
        end

        it 'creates a message for each stop area' do
          subject

          first_expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => second_stop_area.name,
              'transport_mode' => 'Bus'
            },
            source: second_stop_area
          )

          second_expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => third_stop_area.name,
              'transport_mode' => 'Tram'
            },
            source: third_stop_area
          )

          expect(macro_run.macro_messages).to contain_exactly(first_expected_message, second_expected_message)
        end
      end
    end
  end
end
