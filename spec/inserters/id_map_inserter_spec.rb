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

    it "can process a large number of models" do
      count = 100000

      journey_pattern_count = count / 100
      journey_pattern_count.times do |n|
        inserter.register_primary_key!(Chouette::Route, n, journey_pattern_count - n)
        inserter.register_primary_key!(Chouette::JourneyPattern, n, journey_pattern_count - n)
      end

      start = Time.now

      # To obtain the d3 html viewer:
      # bundle exec stackprof --d3-flamegraph tmp/stackprof-id-map-inserter-spec.dump > flamegraph.html
      StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-id-map-inserter-spec-vehicle-journeys.dump') do
        count.times do |n|
          vehicle_journey.id = n+1
          vehicle_journey.journey_pattern_id = vehicle_journey.route_id = n % journey_pattern_count

          inserter.insert(vehicle_journey)
        end
      end

      puts "total: #{Time.now - start} seconds"
      puts "#{(Time.now - start) / count * 1000000 / 60} minutes / million"
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

  end

  it "can process a large number of models" do
    count = 50000

    journey_pattern_count = count / 100
    journey_pattern_count.times do |n|
      inserter.register_primary_key!(Chouette::Route, n, journey_pattern_count - n)
      inserter.register_primary_key!(Chouette::JourneyPattern, n, journey_pattern_count - n)
    end

    stop_point_count = 25 * journey_pattern_count
    stop_point_count.times do |n|
      inserter.register_primary_key!(Chouette::StopPoint, n, stop_point_count - n)
    end

    initial_start = Time.now

    start = Time.now
    vehicle_journey = Chouette::VehicleJourney.new

    # To obtain the d3 html viewer:
    # bundle exec stackprof --d3-flamegraph tmp/stackprof-id-map-inserter-spec.dump > flamegraph.html
    StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-id-map-inserter-spec-vehicle-journeys.dump') do
      count.times do |n|
        vehicle_journey.id = n+1
        vehicle_journey.journey_pattern_id = vehicle_journey.route_id = n % journey_pattern_count

        inserter.insert(vehicle_journey)
      end
    end

    puts "VehicleJourney id mapping: #{Time.now - start} seconds"

    start = Time.now
    vehicle_journey_at_stop = Chouette::VehicleJourneyAtStop.new

    # To obtain the d3 html viewer:
    # bundle exec stackprof --d3-flamegraph tmp/stackprof-id-map-inserter-spec.dump > flamegraph.html
    StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-id-map-inserter-spec-vehicle-journey-at-stops.dump') do
      (25 * count).times do |n|
        vehicle_journey_at_stop.id = n+1
        vehicle_journey_at_stop.vehicle_journey_id = n % count
        vehicle_journey_at_stop.stop_point_id = n % stop_point_count

        inserter.insert(vehicle_journey_at_stop)
      end
    end

    puts "VehicleJourneyAtStop id mapping: #{Time.now - start} seconds"
    puts "#{Chouette::Benchmark.current_usage} MB of memory"
    puts "#{(Time.now - initial_start) / count * 1000000 / 60} minutes / million"
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
