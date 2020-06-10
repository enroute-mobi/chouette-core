RSpec.describe IdMapInserter do

  let(:context) do
    Chouette.create do
      referential
    end
  end

  subject { IdMapInserter.new context.referential }
  alias_method :inserter, :subject

  describe "mapped_model_class?" do

    it "is true for Chouette::VehicleJourney" do
      expect(IdMapInserter.mapped_model_class?(Chouette::VehicleJourney)).to be_truthy
    end

    it "is false for Chouette::VehicleJourney" do
      expect(IdMapInserter.mapped_model_class?(Chouette::Company)).to be_falsy
    end

  end

  def next_id(model_class)
    @next_identifiers ||= Hash.new do |h, klass|
      h[klass] = klass.maximum(:id) || 0
    end
    @next_identifiers[model_class] += 1
  end

  describe "Vehicle Journey" do

    let(:vehicle_journey) { Chouette::VehicleJourney.new id: 42 }

    it "define a new primary key" do
      expect { inserter.insert(vehicle_journey) }.to change(vehicle_journey, :id).to(1)
    end

    it "change route_id with new value" do
      vehicle_journey.route_id = 42

      new_route_id = 4242
      inserter.register_primary_key!(Chouette::Route, vehicle_journey.route_id, new_route_id)

      expect { inserter.insert(vehicle_journey) }.to change(vehicle_journey, :route_id).to(new_route_id)
    end

    it "change journey_pattern_id with new value" do
      vehicle_journey.journey_pattern_id = 42

      new_journey_pattern_id = 4242
      inserter.register_primary_key!(Chouette::JourneyPattern, vehicle_journey.journey_pattern_id, new_journey_pattern_id)

      expect { inserter.insert(vehicle_journey) }.to change(vehicle_journey, :journey_pattern_id).to(new_journey_pattern_id)
    end

    it "keeps company_id value" do
      vehicle_journey.company_id = 42

      expect { inserter.insert(vehicle_journey) }.to_not change(vehicle_journey, :company_id)
    end

    it "inserts 40 000 models / second (1 million in 25s)", :performance do
      # To use Hash with realistic volume
      route_count = 10000
      route_count.times do |n|
        inserter.register_primary_key!(Chouette::Route, n, route_count - n)
        inserter.register_primary_key!(Chouette::JourneyPattern, n, route_count - n)
      end

      expect {
        vehicle_journey.id = next_id(Chouette::VehicleJourney)

        vehicle_journey.route_id = rand(0...route_count)
        vehicle_journey.journey_pattern_id = rand(0...route_count)

        inserter.insert vehicle_journey
      }.to perform_at_least(40000).within(1.second).ips
    end

  end

  describe "ReferentialCode" do

    let(:code) { ReferentialCode.new id: 42 }

    it "define a new primary key" do
      expect { inserter.insert(code) }.to change(code, :id).to(1)
    end

    it "change resource_id with new value" do
      code.resource_type, code.resource_id = 'Chouette::VehicleJourney', 42

      new_resource_id = 4242
      inserter.register_primary_key!(Chouette::VehicleJourney, code.resource_id, new_resource_id)

      expect { inserter.insert(code) }.to change(code, :resource_id).to(new_resource_id)
    end

  end

  describe "VehicleJourneyAtStop" do

    let(:vehicle_journey_at_stop) { Chouette::VehicleJourneyAtStop.new id: 42 }

    it "define a new primary key" do
      expect { inserter.insert(vehicle_journey_at_stop) }.to change(vehicle_journey_at_stop, :id).to(1)
    end

    it "change vehicle_journey_id with new value" do
      vehicle_journey_at_stop.vehicle_journey_id = 42

      new_vehicle_journey_id = 4242
      inserter.register_primary_key!(Chouette::VehicleJourney, vehicle_journey_at_stop.vehicle_journey_id, new_vehicle_journey_id)

      expect { inserter.insert(vehicle_journey_at_stop) }.to change(vehicle_journey_at_stop, :vehicle_journey_id).to(new_vehicle_journey_id)
    end

    it "inserts 70 000 models / second (25 million in ~360s)", :performance do
      # To use Hash with realistic volume
      stop_point_count = 250000
      stop_point_count.times do |n|
        inserter.register_primary_key!(Chouette::StopPoint, n, stop_point_count - n)
      end

      vehicle_journey_count = 1000000
      vehicle_journey_count.times do |n|
        inserter.register_primary_key!(Chouette::VehicleJourney, n, vehicle_journey_count - n)
      end

      expect {
        vehicle_journey_at_stop.id = next_id(Chouette::VehicleJourneyAtStop)

        vehicle_journey_at_stop.vehicle_journey_id = rand(0...vehicle_journey_count)
        vehicle_journey_at_stop.stop_point_id = rand(0...stop_point_count)

        inserter.insert vehicle_journey_at_stop
      }.to perform_at_least(70000).within(1.second).ips
    end

  end

  describe "TimeTablesVehicleJourney" do

    let(:model) do
      Chouette::TimeTablesVehicleJourney.new
    end

    it "change route_id with new value" do
      model.time_table_id = 42

      new_time_table_id = 4242
      inserter.register_primary_key!(Chouette::TimeTable, model.time_table_id, new_time_table_id)

      expect { inserter.insert(model) }.to change(model, :time_table_id).to(new_time_table_id)
    end

    it "change route_id with new value" do
      model.vehicle_journey_id = 42

      new_vehicle_journey_id = 4242
      inserter.register_primary_key!(Chouette::VehicleJourney, model.vehicle_journey_id, new_vehicle_journey_id)

      expect { inserter.insert(model) }.to change(model, :vehicle_journey_id).to(new_vehicle_journey_id)
    end

  end

end
