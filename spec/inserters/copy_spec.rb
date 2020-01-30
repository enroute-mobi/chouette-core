require "rails_helper"

RSpec.describe CopyInserter do

  let(:context) do
    Chouette.create do
      vehicle_journey
    end
  end

  before do
    context.referential.switch
  end

  let(:vehicle_journey) { context.vehicle_journey.reload }

  it "creates a CSV with required values" do
    expected_csv = Chouette::VehicleJourney.copy_to_string

    inserter = CopyInserter.new
    inserter.insert vehicle_journey

    expect(inserter.csv_content).to eq(expected_csv)
  end

  it "creates a CSV with required values" do
    vehicle_journey.id = 2

    # TODO ...
    vehicle_journey.objectid = nil
    vehicle_journey.before_validation_objectid

    inserter = CopyInserter.new
    inserter.insert vehicle_journey

    expect { inserter.flush }.to change(Chouette::VehicleJourney, :count).by(1)
  end

  it "can process a large number of models" do
    inserter = CopyInserter.new

    count = 100000
    start = Time.now

    StackProf.run(mode: :cpu, raw: true, out: 'tmp/stackprof-copy-spec-insertions.dump') do
      count.times do |n|
        vehicle_journey.id = n+2

        vehicle_journey.objectid = "chouette:VehicleJourney:#{n}:LOC"
        #vehicle_journey.objectid = nil
        #vehicle_journey.before_validation_objectid

        inserter.insert vehicle_journey
      end
    end
    puts "insertion: #{Time.now - start} seconds"

    start = Time.now
    expect { inserter.flush }.to change(Chouette::VehicleJourney, :count).by(count)
    puts "flush: #{Time.now - start} seconds"
  end


  it "creates a CSV with required values (manual method)" do
    # id,route_id,journey_pattern_id,company_id,objectid,object_version,comment,transport_mode,published_journey_name,published_journey_identifier,facility,vehicle_type_identifier,number,mobility_restricted_suitability,flexible_service,journey_category,created_at,updated_at,checksum,checksum_source,data_source_ref,custom_field_values,metadata,ignored_routing_contraint_zone_ids,ignored_stop_area_routing_constraint_ids,line_notice_ids
    # 1,1,1,,chouette:VehicleJourney:e85cd7db-c075-42cf-84d7-a843a2be6703:LOC,,,,Vehicle Journey 1,,,,0,,,0,2020-01-30 16:34:21.532754,2020-01-30 16:34:21.532754,77c1a20e238b705c5497e6fd798b0c6bb6cd7aa740629e6017dbd93db85225bf,"Vehicle Journey 1|-|-|-|-|b1c0ac4b48e0db6883d4cf8d89bfc0c9968284314445f95569204626db9c22e8,26a01fd4614dc6727f570b0fab086dbe6f6f257380155cbfef50e6bc09cfdbb4,67fa970301ef67e188316f09c372a0efb349a0dce777b9301e3b37fcc3cdb9c8",DATASOURCEREF_EDITION_BOIV,{},{},{},{},{}
    expected_csv = Chouette::VehicleJourney.copy_to_string
    expected_headers, _ = expected_csv.split("\n")

    columns = Chouette::VehicleJourney.columns

    connection = Chouette::VehicleJourney.connection

    headers = columns.map(&:name)
    expect(headers.join(',')).to eq(expected_headers)

    column_values = []

    ap vehicle_journey

    attributes = vehicle_journey.attributes
    columns.each do |column|
      attribute_name = column.name
      attribute_value = attributes[attribute_name]

      column_value = connection.type_cast(attribute_value, column)
      column_values << column_value
    end

    ap column_values

    csv_string = CSV.generate do |csv|
      csv << headers
      csv << column_values
    end

    expect(csv_string).to eq(expected_csv)
  end

end
