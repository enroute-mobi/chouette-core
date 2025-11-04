# frozen_string_literal: true

RSpec.describe Macro::ComputeJourneyPatternDistances do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::ComputeJourneyPatternDistances::Run do
    subject(:macro_run) { described_class.create!(macro_list_run: macro_list_run, position: 0) }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do # rubocop:disable Metrics/BlockLength
        workbench do # rubocop:disable Metrics/BlockLength
          stop_area :stop_area1, latitude: 43.574325, longitude: 7.091888
          stop_area :stop_area2, latitude: 43.575067, longitude: 7.095608
          stop_area :stop_area3, latitude: 43.574477, longitude: 7.099041
          stop_area :stop_area4, latitude: 43.574483, longitude: 7.099103
          stop_area :stop_area5, latitude: 43.573539, longitude: 7.100330

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

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area1
              stop_point stop_area: :stop_area2
              stop_point stop_area: :stop_area3
              stop_point stop_area: :stop_area4
              stop_point stop_area: :stop_area5

              journey_pattern name: 'journey pattern name 1', costs: {}, shape: :shape do
                # vehicle_journey # TODO remove?
              end
            end
          end
        end
      end
    end
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:journey_pattern) { context.journey_pattern }
    let(:first_stop) { context.stop_area(:stop_area1) }
    let(:second_stop) { context.stop_area(:stop_area2) }
    let(:third_stop) { context.stop_area(:stop_area3) }
    let(:fourth_stop) { context.stop_area(:stop_area4) }
    let(:fifth_stop) { context.stop_area(:stop_area5) }
    let(:shape) { context.shape(:shape) }
    let(:macro_list_run) { workbench.macro_list_runs.new(referential: referential) }

    describe '#run' do
      subject { macro_run.run }

      before { referential.switch }

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

  describe Macro::ComputeJourneyPatternDistances::Run::Batch do
    subject { JSON.parse batch.query.distances.to_h[second_journey_pattern.id] }

    let(:context) do # rubocop:disable Metrics/BlockLength
      Chouette.create do
        stop_area :first, latitude: 43.574325, longitude: 7.091888
        stop_area :middle, latitude: 43.575067, longitude: 7.095608
        stop_area :last, latitude: 43.574477, longitude: 7.099041

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

        referential do
          route :first, stop_areas: %i[first middle last] do
            journey_pattern :first, name: 'First'
            journey_pattern :second, name: 'Second', shape: :shape
          end
        end
      end
    end

    let(:referential) { context.referential }
    let(:first_journey_pattern) { context.journey_pattern(:first) }
    let(:second_journey_pattern) { context.journey_pattern(:second) }

    let(:first_stop) { context.stop_area(:first) }
    let(:second_stop) { context.stop_area(:middle) }
    let(:third_stop) { context.stop_area(:last) }

    let(:expected_costs) do 
      [
        { "#{first_stop.id}-#{second_stop.id}" => 327 },
        { "#{second_stop.id}-#{third_stop.id}" => 306 }
      ]
    end

    let(:batch) { described_class.new(referential.journey_patterns.to_a)}

    before do 
      referential.switch

      first_journey_pattern.update costs: {
        "#{first_stop.id}-#{second_stop.id}" => {:distance => 100},
        "#{second_stop.id}-#{third_stop.id}" => {:distance => 200}
      }
    end

    it { expect(batch.journey_patterns).to contain_exactly second_journey_pattern }
    it { is_expected.to match_array expected_costs }
  end
end
