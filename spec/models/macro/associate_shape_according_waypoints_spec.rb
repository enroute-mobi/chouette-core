# frozen_string_literal: true

RSpec.describe Macro::AssociateShapeAccordingWaypoints do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::AssociateShapeAccordingWaypoints::Run do
    let(:macro_run) { Macro::AssociateShapeAccordingWaypoints::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end

    describe '#run' do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do

          stop_area :first, latitude: 43.574325, longitude: 7.091888
          stop_area :middle, latitude: 43.575067, longitude: 7.095608
          stop_area :last, latitude: 43.574477, longitude: 7.099041

          shape :selected_shape, geometry: %{LINESTRING (7.091885616516534 43.57432715792825,
            7.092105740785468 43.574444133071914, 7.092232913989094 43.57448386864411,
            7.092297572624793 43.57451721573902, 7.0938826065460825 43.57495548692632,
            7.094136957654024 43.57503495393627, 7.094338294145095 43.575071568446965,
            7.0945759962426465 43.57509763689846, 7.0950863362075465 43.57512125399119,
            7.095554590215809 43.57508352504564, 7.095602600334812 43.57506347285972,
            7.095652755893213 43.57507037931442, 7.096488950614554 43.57498110270073,
            7.096944842578117 43.57494388804128, 7.097292355099007 43.57494729754658,
            7.097428315768137 43.57494157611041, 7.097690738820565 43.57496659774533,
            7.097939371027158 43.57497416655492, 7.098088407276881 43.57497691033764,
            7.0983814708545685 43.574919493893006, 7.098513137846123 43.57485985393559,
            7.098762679794674 43.57472312144432, 7.099021002288743 43.57454093709573,
            7.099040712595973 43.57447699307644)
          }

          shape :other_shape

          referential do
            route stop_areas: %i[first middle last] do
              journey_pattern :updated_journey_pattern, shape: nil
            end

            route stop_areas: %i[first last] do
              journey_pattern :other_journey_pattern, shape: nil
            end
          end
        end
      end

      let(:first_stop_area) { context.stop_area(:first) }
      let(:middle_stop_area) { context.stop_area(:middle) }
      let(:last_stop_area) { context.stop_area(:last) }

      let(:selected_shape) { context.shape(:selected_shape) }
      let(:other_shape) { context.shape(:other_shape) }

      let(:updated_journey_pattern) { context.journey_pattern(:updated_journey_pattern) }

      before do
        context.referential.switch

        selected_shape.waypoints.create([
          {
            name: first_stop_area.name,
            position: 0,
            waypoint_type: "waypoint",
            coordinates: [ first_stop_area.longitude, first_stop_area.latitude ],
            stop_area: first_stop_area
          },
          {
            name: middle_stop_area.name,
            position: 1,
            waypoint_type: "waypoint",
            coordinates: [ middle_stop_area.longitude, middle_stop_area.latitude ],
            stop_area: middle_stop_area
          },
          {
            name: last_stop_area.name,
            position: 2,
            waypoint_type: "waypoint",
            coordinates: [ last_stop_area.longitude, last_stop_area.latitude ],
            stop_area: last_stop_area
          }
        ])
      end

      it 'should find and associate shape with journey pattern' do
        expect { subject }.to change { updated_journey_pattern.reload.shape }.from(nil).to(selected_shape)
      end

      it 'creates a message for each journay pattern' do
        subject

        expected_message = an_object_having_attributes(
          criticity: 'info',
          message_attributes: {
            'name' => updated_journey_pattern.name,
            'shape' => selected_shape.reload.name
          },
          source: updated_journey_pattern
        )

        expect(macro_run.macro_messages).to include(expected_message)
      end

      context 'when the JourneyPattern has already a Shape' do
        before { updated_journey_pattern.update! shape: other_shape }

        it "doesn't change the Journey Pattern Shape" do
          expect { subject }.to_not(change { updated_journey_pattern.reload.shape })
        end
      end
    end
  end
end
