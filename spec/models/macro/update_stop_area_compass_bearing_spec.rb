RSpec.describe Macro::UpdateStopAreaCompassBearing do

  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::UpdateStopAreaCompassBearing::Run do
    subject(:macro_run) { Macro::UpdateStopAreaCompassBearing::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: context.referential, workbench: context.workbench
    end

    describe "#run" do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          # See CHOUETTE-1662 for visual view
          stop_area :first, latitude: 43.574325, longitude: 7.091888
          stop_area :middle, latitude: 43.575067, longitude: 7.095608
          stop_area :last, latitude: 43.574477, longitude: 7.099041
          stop_area :no_relationship_with_shape, latitude: 43.974477, longitude: 7.899041

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
            route stop_areas: [:first, :middle, :last] do
              journey_pattern shape: :shape
            end
          end
        end
      end

      before do
        context.referential.switch
      end

      def stop_area(name)
        context.stop_area(name).reload
      end

      describe '#scope' do
        subject { macro_run.stop_areas.find_by(id: stop_area(:no_relationship_with_shape)) }

        it 'shoud not contain no_relationship_with_shape stop area' do
          is_expected.to be_nil
        end
      end

      it "should compute and update Stop Area compass bearings" do
        expect { subject }.to change { stop_area(:first).reload.compass_bearing }.to(62.0)
                                .and change { stop_area(:middle).compass_bearing }.to(96.4)
                                       .and change { stop_area(:last).compass_bearing }.to(125.7)
      end

      it "creates a message for each Stop Area" do
        subject

        expected_messages = %i{first middle last}.map do |stop_area_name|
          an_object_having_attributes(source: stop_area(stop_area_name))
        end

        expect(macro_run.macro_messages).to include(*expected_messages)
      end
    end
  end
end
