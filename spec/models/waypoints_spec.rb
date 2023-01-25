RSpec.describe "Waypoint" do

  let(:context) do
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
        route stop_areas: %i[first middle last] do
          journey_pattern :journey_pattern, shape: :shape
        end
      end
    end
  end

  let(:first_stop_area) { context.stop_area(:first) }
  let(:middle_stop_area) { context.stop_area(:middle) }
  let(:last_stop_area) { context.stop_area(:last) }

  let(:shape) { context.shape(:shape) }
  let(:shape_provider) { shape.shape_provider }
  let(:shape_provider) { shape.shape_provider }

  let(:journey_pattern) { context.journey_pattern(:journey_pattern) }

  before do
    context.referential.switch
  end

  describe "#validation" do

    subject(:waypoint) do
      Waypoint.new({
        name: first_stop_area.name,
        position: 0,
        stop_area: stop_area,
        coordinates: [
          first_stop_area.longitude,
          first_stop_area.latitude
        ],
        waypoint_type: waypoint_type,
        shape: shape
      })
    end

    context "when waypoint_type is not 'waypoint'" do

      let(:waypoint_type) { 'constraint' }
      let(:stop_area) { nil }

      it { is_expected.to be_valid }
    end

    context "when waypoint_type is 'waypoint'" do

      let(:waypoint_type) { 'waypoint' }

      context 'and without stop_area' do
        let(:stop_area) { nil }

        it { is_expected.to_not be_valid }
      end

      context 'and with stop_area' do
        let(:stop_area) { first_stop_area }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#shape" do

    let(:create_shape) do
      shape_provider.shapes.create(
        name: 'shape',
        geometry: shape.geometry,
        waypoints: journey_pattern.waypoints,
        shape_referential: shape.shape_referential
      )
    end

    subject { create_shape.waypoints.map(&:stop_area) }

    it "should crate waypoints associated with stop areas" do 
      is_expected.to match_array([first_stop_area, middle_stop_area, last_stop_area])
    end
  end

end
