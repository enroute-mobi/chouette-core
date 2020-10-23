RSpec.describe CopyInserter do

  before do
    context.referential.switch
  end

  subject { CopyInserter.new context.referential }
  alias_method :inserter, :subject

  def truncate_timestamps(model)
    # To avoid situations where we're saving '2020-03-05 10:33:55.56506'
    # and reading (via copy_to_string) '2020-03-05 10:33:55.565060'
    #
    # With 'truncated' timestamps, we're saving/reading '2020-03-05 10:56:35'
    model.update(created_at: model.created_at.change(:usec => 0),
                 updated_at: model.updated_at.change(:usec => 0))
    model
  end

  def next_id(model_class)
    @next_identifiers ||= Hash.new do |h, klass|
      h[klass] = klass.maximum(:id) || 0
    end
    @next_identifiers[model_class] += 1
  end

  describe "Vehicle Journey" do

    before do
      truncate_timestamps vehicle_journey
    end

    let(:vehicle_journey) do
      context.vehicle_journey.reload
    end

    let(:context) do
      Chouette.create do
        route stop_count: 25 do
          vehicle_journey
        end
      end
    end

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

    describe "Stops" do

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

  describe 'Referential Code' do

    let(:context) do
      Chouette.create do
        vehicle_journey
      end
    end

    let(:vehicle_journey) { context.vehicle_journey.reload }
    let(:code_space) { context.workgroup.code_spaces.default }
    let!(:code) { truncate_timestamps(vehicle_journey.codes.create!(code_space: code_space, value: 'dummy')) }

    it "creates the same CSV content than PostgreSQL gives by COPY TO" do
      expected_csv = ReferentialCode.copy_to_string
      inserter.insert code
      expect(inserter.for(ReferentialCode).csv_content).to eq(expected_csv)
    end

    it "inserts model in database" do
      code.id = next_id(Referential)
      code.value = 'other'

      inserter.insert code

      expect { inserter.flush }.to change(ReferentialCode, :count).by(1)
    end

  end


  describe "TimeTables" do

    let(:context) do
      Chouette.create do
        time_table periods: [ Time.zone.today..1.month.from_now.to_date ],
                   dates_included: Time.zone.today - 10,
                   dates_excluded: Time.zone.today + 10
      end
    end

    let(:time_table) { context.time_table }

    it "creates the same CSV content than PostgreSQL gives by COPY TO" do
      expected_csv = Chouette::TimeTable.copy_to_string
      inserter.insert time_table

      expect(inserter.for(Chouette::TimeTable).csv_content).to eq(expected_csv)
    end

    it "inserts model in database" do
      time_table.id = next_id(Chouette::TimeTable)
      time_table.objectid = "chouette:TimeTable:#{time_table.id}:LOC"

      inserter.insert time_table

      expect { inserter.flush }.to change(Chouette::TimeTable, :count).by(1)
    end

    describe "Dates" do

      let(:dates) { time_table.dates }
      let(:date) { dates.first }

      it "creates the same CSV content than PostgreSQL gives by COPY TO" do
        expected_csv = Chouette::TimeTableDate.copy_to_string
        dates.each { |date| inserter.insert date }

        expect(inserter.for(Chouette::TimeTableDate).csv_content).to eq(expected_csv)
      end

      it "inserts model in database" do
        date.id = next_id(Chouette::TimeTableDate)

        inserter.insert date

        expect { inserter.flush }.to change(Chouette::TimeTableDate, :count).by(1)
      end

      it "inserts 50000 models / second (1 million in 20s)", :performance do
        expect {
          date.id = next_id(Chouette::TimeTableDate)
          inserter.insert date
        }.to perform_at_least(50000).within(1.seconds).ips
      end

    end

    describe "Periods" do

      let(:periods) { time_table.periods }
      let(:period) { periods.first }

      it "creates the same CSV content than PostgreSQL gives by COPY TO" do
        expected_csv = Chouette::TimeTablePeriod.copy_to_string
        periods.each { |period| inserter.insert period }

        expect(inserter.for(Chouette::TimeTablePeriod).csv_content).to eq(expected_csv)
      end

      it "inserts model in database" do
        period.id = next_id(Chouette::TimeTablePeriod)

        inserter.insert period

        expect { inserter.flush }.to change(Chouette::TimeTablePeriod, :count).by(1)
      end

    end

  end

end
