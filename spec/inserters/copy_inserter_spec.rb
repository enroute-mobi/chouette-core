RSpec.describe CopyInserter do

  let(:context) do
    Chouette.create do
      route stop_count: 25 do
        vehicle_journey
      end
    end
  end

  before do
    context.referential.switch
  end

  subject { CopyInserter.new context.referential }
  alias_method :inserter, :subject

  let(:vehicle_journey) { context.vehicle_journey.reload }

  describe "Vehicle Journey" do

    it "creates the same CSV content than PostgreSQL gives by COPY TO" do
      expected_csv = Chouette::VehicleJourney.copy_to_string
      inserter.insert vehicle_journey
      expect(inserter.for(Chouette::VehicleJourney).csv_content).to eq(expected_csv)
    end

    it "inserts model in database" do
      vehicle_journey.id = Chouette::VehicleJourney.maximum(:id) + 1

      # TODO ...
      vehicle_journey.objectid = nil
      vehicle_journey.before_validation_objectid

      inserter.insert vehicle_journey

      expect { inserter.flush }.to change(Chouette::VehicleJourney, :count).by(1)
    end

  end

  describe "Vehicle Journey At Stops" do

    let!(:vehicle_journey_at_stop) do
      vehicle_journey.vehicle_journey_at_stops.first
    end

    it "creates the same CSV content than PostgreSQL gives by COPY TO" do
      expected_csv =
        Chouette::VehicleJourneyAtStop.where(id: vehicle_journey_at_stop).copy_to_string
      inserter.insert vehicle_journey_at_stop
      expect(inserter.for(Chouette::VehicleJourneyAtStop).csv_content).to eq(expected_csv)
    end

    it "inserts model in database" do
      vehicle_journey.id = Chouette::VehicleJourney.maximum(:id) + 1
      # TODO ...
      vehicle_journey.objectid = nil
      vehicle_journey.before_validation_objectid

      vehicle_journey_at_stop.id = Chouette::VehicleJourneyAtStop.maximum(:id) + 1
      vehicle_journey_at_stop.vehicle_journey_id = vehicle_journey.id

      inserter.insert vehicle_journey
      inserter.insert vehicle_journey_at_stop

      expect { inserter.flush }.to change(Chouette::VehicleJourneyAtStop, :count).by(1)
    end

  end

  it "can process a large number of models" do
    inserter = CopyInserter.new(context.referential)

    count = 10000
    initial_start = start = Time.now

    vehicle_journey_at_stops = vehicle_journey.vehicle_journey_at_stops.to_a

    # StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-copy-spec-vehicle-journeys.dump') do
      count.times do |n|
        vehicle_journey.id = n+2

        # We dont't want to benchmark objectid code so:
        #
        # vehicle_journey.objectid = nil
        # vehicle_journey.before_validation_objectid
        #
        # is replaced by:
        vehicle_journey.objectid = "chouette:VehicleJourney:#{n}:LOC"

        inserter.insert vehicle_journey
      end
    # end
    puts "VehicleJourney insertion: #{Time.now - start} seconds"

    start = Time.now

    # To obtain the d3 html viewer:
    # bundle exec stackprof --d3-flamegraph tmp/stackprof-copy-spec-vehicle-journey-at-stops.dump > flamegraph.html
    StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-copy-spec-vehicle-journey-at-stops.dump') do
      next_vehicle_journey_at_stop_id = Chouette::VehicleJourneyAtStop.maximum(:id) + 1
      count.times do |n|
        vehicle_journey_at_stops.each do |vehicle_journey_at_stop|
          vehicle_journey_at_stop.id = next_vehicle_journey_at_stop_id
          next_vehicle_journey_at_stop_id += 1

          vehicle_journey_at_stop.vehicle_journey_id = n+2
          inserter.insert vehicle_journey_at_stop
        end
      end
    end

    puts "VehicleJourneyAtStop insertion: #{Time.now - start} seconds"

    start = Time.now
    expect { inserter.flush }.to change(Chouette::VehicleJourney, :count).by(count)
    puts "flush: #{Time.now - start} seconds"

    puts "total: #{Time.now - initial_start} seconds"
    puts "#{(Time.now - initial_start) / count * 1000000 / 60} minutes / million"
  end

  context "manual method" do

    it "creates a CSV with required values for VehicleJourney" do
      # id,route_id,journey_pattern_id,company_id,objectid,object_version,comment,transport_mode,published_journey_name,published_journey_identifier,facility,vehicle_type_identifier,number,mobility_restricted_suitability,flexible_service,journey_category,created_at,updated_at,checksum,checksum_source,data_source_ref,custom_field_values,metadata,ignored_routing_contraint_zone_ids,ignored_stop_area_routing_constraint_ids,line_notice_ids
      # 1,1,1,,chouette:VehicleJourney:e85cd7db-c075-42cf-84d7-a843a2be6703:LOC,,,,Vehicle Journey 1,,,,0,,,0,2020-01-30 16:34:21.532754,2020-01-30 16:34:21.532754,77c1a20e238b705c5497e6fd798b0c6bb6cd7aa740629e6017dbd93db85225bf,"Vehicle Journey 1|-|-|-|-|b1c0ac4b48e0db6883d4cf8d89bfc0c9968284314445f95569204626db9c22e8,26a01fd4614dc6727f570b0fab086dbe6f6f257380155cbfef50e6bc09cfdbb4,67fa970301ef67e188316f09c372a0efb349a0dce777b9301e3b37fcc3cdb9c8",DATASOURCEREF_EDITION_BOIV,{},{},{},{},{}

      expected_csv = Chouette::VehicleJourney.copy_to_string
      expected_headers, _ = expected_csv.split("\n")

      columns = Chouette::VehicleJourney.columns

      connection = Chouette::VehicleJourney.connection

      headers = columns.map(&:name)
      expect(headers.join(',')).to eq(expected_headers)

      column_values = []

      attributes = vehicle_journey.attributes
      columns.each do |column|
        attribute_name = column.name
        attribute_value = attributes[attribute_name]

        column_value = connection.type_cast(attribute_value, column)
        column_values << column_value
      end

      csv_string = CSV.generate do |csv|
        csv << headers
        csv << column_values
      end

      expect(csv_string).to eq(expected_csv)
    end

  end

end
