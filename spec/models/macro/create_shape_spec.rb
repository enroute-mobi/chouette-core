RSpec.describe Macro::CreateShape do

  before(:each) do
    shape_response = {"formatVersion"=>"0.0.12",
    "routes"=>
     [{"summary"=>
        {"lengthInMeters"=>621,
         "travelTimeInSeconds"=>98,
         "trafficDelayInSeconds"=>0,
         "trafficLengthInMeters"=>0,
         "departureTime"=>"2022-02-23T09:37:17+01:00",
         "arrivalTime"=>"2022-02-23T09:38:54+01:00"},
       "legs"=>
        [{"summary"=>
           {"lengthInMeters"=>318,
            "travelTimeInSeconds"=>38,
            "trafficDelayInSeconds"=>0,
            "trafficLengthInMeters"=>0,
            "departureTime"=>"2022-02-23T09:37:17+01:00",
            "arrivalTime"=>"2022-02-23T09:37:55+01:00"},
          "points"=>
           [{"latitude"=>43.57434, "longitude"=>7.09188},
            {"latitude"=>43.57443, "longitude"=>7.0921},
            {"latitude"=>43.57453, "longitude"=>7.09248},
            {"latitude"=>43.57459, "longitude"=>7.09261},
            {"latitude"=>43.57462, "longitude"=>7.09271},
            {"latitude"=>43.57479, "longitude"=>7.0933},
            {"latitude"=>43.57492, "longitude"=>7.09373},
            {"latitude"=>43.57504, "longitude"=>7.0942},
            {"latitude"=>43.57511, "longitude"=>7.09459},
            {"latitude"=>43.57511, "longitude"=>7.09483},
            {"latitude"=>43.57512, "longitude"=>7.095},
            {"latitude"=>43.5751, "longitude"=>7.09539},
            {"latitude"=>43.57509, "longitude"=>7.09549},
            {"latitude"=>43.57508, "longitude"=>7.09561}]},
         {"summary"=>
           {"lengthInMeters"=>303,
            "travelTimeInSeconds"=>60,
            "trafficDelayInSeconds"=>0,
            "trafficLengthInMeters"=>0,
            "departureTime"=>"2022-02-23T09:37:55+01:00",
            "arrivalTime"=>"2022-02-23T09:38:54+01:00"},
          "points"=>
           [{"latitude"=>43.57508, "longitude"=>7.09561},
            {"latitude"=>43.57505, "longitude"=>7.09601},
            {"latitude"=>43.57499, "longitude"=>7.09676},
            {"latitude"=>43.57495, "longitude"=>7.09686},
            {"latitude"=>43.57495, "longitude"=>7.09717},
            {"latitude"=>43.57495, "longitude"=>7.09743},
            {"latitude"=>43.57495, "longitude"=>7.098},
            {"latitude"=>43.57495, "longitude"=>7.09805},
            {"latitude"=>43.57497, "longitude"=>7.0982},
            {"latitude"=>43.57494, "longitude"=>7.09838},
            {"latitude"=>43.57493, "longitude"=>7.09844},
            {"latitude"=>43.57491, "longitude"=>7.09853},
            {"latitude"=>43.57488, "longitude"=>7.09857},
            {"latitude"=>43.57483, "longitude"=>7.09864},
            {"latitude"=>43.57468, "longitude"=>7.09883},
            {"latitude"=>43.5745, "longitude"=>7.09907}]}],
       "sections"=>[{"startPointIndex"=>0, "endPointIndex"=>29, "sectionType"=>"TRAVEL_MODE", "travelMode"=>"bus"}]}]}
    stub_request(:get, "https://api.tomtom.com/routing/1/calculateRoute/43.574325,7.091888:43.575067,7.095608:43.574477,7.099041/json?routeType=fastest&traffic=false&travelMode=bus&key=mock_tomtom_api_key").
    to_return(status: 200, body: shape_response.to_json)
  end

  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateShape::Run do
    let(:macro_list_run) do
      Macro::List::Run.new referential: context.referential, workbench: context.workbench
    end
    subject(:macro_run) { Macro::CreateShape::Run.new macro_list_run: macro_list_run }

    describe ".run" do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do

          stop_area :first, name: "first", latitude: 43.574325, longitude: 7.091888
          stop_area :middle, name: "middle", latitude: 43.575067, longitude: 7.095608
          stop_area :last, name: "last", latitude: 43.574477, longitude: 7.099041

          referential do
            route stop_areas: [:first, :middle, :last] do
              journey_pattern id: 1, shape: nil
            end
          end
        end
      end

      let(:journey_pattern) { context.journey_pattern }
      let(:workgroup) { context.workgroup }

      before do
        context.referential.switch
        workgroup.owner.update features: ["route_planner"]
      end

      context "when the JourneyPattern has no Shape" do
        let(:shape) { Shape.first }
        let(:geom) { journey_pattern.reload.shape&.geometry.to_s }

        it "should create shape" do
          expect { subject }.to change { Shape.count }.from(0).to(1)
        end

        it "should update association between Journey Pattern and Shape" do
          subject

          expect change { journey_pattern.reload.shape }.from(nil).to(shape)
        end
      end
    end
  end
end
