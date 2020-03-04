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

  def next_id(model_class)
    @next_identifiers ||= Hash.new do |h, klass|
      h[klass] = klass.maximum(:id) || 0
    end
    @next_identifiers[model_class] += 1
  end

  describe "Vehicle Journey" do

    it "creates the same CSV content than PostgreSQL gives by COPY TO" do
      expected_csv = Chouette::VehicleJourney.copy_to_string
      inserter.insert vehicle_journey
      expect(inserter.for(Chouette::VehicleJourney).csv_content).to eq(expected_csv)
    end

    it "inserts model in database" do
      vehicle_journey.id = next_id(Chouette::VehicleJourney)
      vehicle_journey.objectid = "chouette:VehicleJourney:#{vehicle_journey.id}:LOC"

      inserter.insert vehicle_journey

      expect { inserter.flush }.to change(Chouette::VehicleJourney, :count).by(1)
    end

    it "inserts 3000 models / second (1 million in 333s)", :performance do
      expect {
        vehicle_journey.id = next_id(Chouette::VehicleJourney)
        vehicle_journey.objectid = "chouette:VehicleJourney:#{vehicle_journey.id}:LOC"

        inserter.insert vehicle_journey
      }.to perform_at_least(3000).within(1.second).ips
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
      vehicle_journey_at_stop.id = next_id(Chouette::VehicleJourneyAtStop)
      vehicle_journey_at_stop.vehicle_journey_id = vehicle_journey.id

      inserter.insert vehicle_journey_at_stop

      expect { inserter.flush }.to change(Chouette::VehicleJourneyAtStop, :count).by(1)
    end

    it "inserts 50 000 models / second (25 millions in 500s)", :performance do
      expect {
        vehicle_journey_at_stop.id = next_id(Chouette::VehicleJourneyAtStop)

        inserter.insert vehicle_journey_at_stop
      }.to perform_at_least(50000).within(1.second).ips
    end

  end

end
