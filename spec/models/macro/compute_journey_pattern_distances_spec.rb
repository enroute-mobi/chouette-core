# frozen_string_literal: true

RSpec.describe Macro::ComputeJourneyPatternDistances do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::ComputeJourneyPatternDistances::Run do
    let(:context) do
      Chouette.create do
        shape :shape, geometry: %{LINESTRING (7.091885616516534 43.57432715792825,
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
          7.099040712595973 43.57447699307644, 7.099103228010209 43.57448337768834,
          7.100330152274983 43.57353910368734)
        }
      end
    end

    let(:macro_run) { Macro::ComputeJourneyPatternDistances::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: referential.workbench
    end

    let!(:at_stop) { create(:vehicle_journey_at_stop) }
    let!(:vehicle_journey) { at_stop.vehicle_journey }
    let!(:journey_pattern) { vehicle_journey.journey_pattern }
    let!(:referential) { journey_pattern.referential }

    let!(:first_at_stop) { journey_pattern.vehicle_journey_at_stops.first }
    let!(:second_at_stop) { journey_pattern.vehicle_journey_at_stops.second }
    let!(:third_at_stop) { journey_pattern.vehicle_journey_at_stops.third }
    let!(:fourth_at_stop) { journey_pattern.vehicle_journey_at_stops.fourth }
    let!(:fifth_at_stop) { journey_pattern.vehicle_journey_at_stops.fifth }

    let!(:first_stop) { first_at_stop.stop_point.stop_area }
    let!(:second_stop) { second_at_stop.stop_point.stop_area }
    let!(:third_stop) { third_at_stop.stop_point.stop_area }
    let!(:fourth_stop) { fourth_at_stop.stop_point.stop_area }
    let!(:fifth_stop) { fifth_at_stop.stop_point.stop_area }

    let(:shape) { context.shape(:shape) }

    describe '#run' do
      subject { macro_run.run }

      before do
        referential.switch

        journey_pattern.update name: 'journey pattern name 1', costs: {}, shape: shape

        first_stop.update   latitude: 43.574325, longitude: 7.091888
        second_stop.update  latitude: 43.575067, longitude: 7.095608
        third_stop.update   latitude: 43.574477, longitude: 7.099041
        fourth_stop.update  latitude: 43.574483, longitude: 7.099103
        fifth_stop.update   latitude: 43.573539, longitude: 7.100330
      end

      it 'should compute and update Journey Pattern costs' do
        expected_costs = {
          "#{first_stop.id}-#{second_stop.id}" => { 'distance' => 327 },
          "#{second_stop.id}-#{third_stop.id}" => { 'distance' => 306 },
          "#{third_stop.id}-#{fourth_stop.id}" => { 'distance' => 5 },
          "#{fourth_stop.id}-#{fifth_stop.id}" => { 'distance' => 131 }
        }
        expect { subject }.to change { journey_pattern.reload.costs }.to(expected_costs)
      end

      it 'creates a message for each journey_pattern' do
        subject

        expect(macro_run.macro_messages).to include(
          an_object_having_attributes({
                                        criticity: 'info',
                                        message_attributes: { 'name' => 'journey pattern name 1' },
                                        source: journey_pattern
                                      })
        )
      end
    end
  end
end
