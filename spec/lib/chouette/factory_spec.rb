require "rails_helper"

RSpec.describe Chouette::Factory do

  it "should raise error when type isn't known" do
    expect {
      Chouette::Factory.create { dummy }
    }.to raise_error(NameError)
  end

  it "should create workgroup" do
    expect {
      Chouette::Factory.create { workgroup }
    }.to change { Workgroup.count }
  end

  it "should create line_referential" do
    expect {
      Chouette::Factory.create do
        workgroup do
          line_referential
        end
      end
    }.to change { LineReferential.count }
  end

  describe "Referentials" do
    describe "{ referential }" do
      before do
        Chouette::Factory.create { referential }
      end

      it "should create a Referential" do
        expect(Referential.count).to eq(2)
      end

    end

    describe "{ referential name: 'Test' }" do
      before do
        Chouette::Factory.create { referential name: "Test" }
      end

      it "should create a Referential with name 'Test'" do
        expect(Referential.last.name).to eq('Test')
      end
    end

    describe "{ referential :test, name: 'Test' }" do
      let(:factory) do
        Chouette::Factory.create { referential :test, name: "Test" }
      end

      let(:referential) { factory.instance :test }

      it "should create a Referential :test with name 'Test'" do
        expect(referential.name).to eq('Test')
      end
    end
  end

  describe "VehicleJourneys" do
    describe "{ vehicle_journey }" do
      before do
        Chouette::Factory.create { vehicle_journey }
      end

      it "should create VehicleJourney" do
        Referential.last.switch do
          expect(Chouette::VehicleJourney.count).to eq(1)
        end
      end

      it "should create VehicleJourney with 3 stops" do
        Referential.last.switch do
          expect(Chouette::VehicleJourney.last.vehicle_journey_at_stops.count).to eq(3)
        end
      end
    end
  end

  describe "TimeTables" do

    describe "{ time_table }" do
      before do
        Chouette::Factory.create do
          time_table
        end
      end

      it "should create TimeTable with default period" do
        Referential.last.switch do
          expect(Chouette::TimeTable.count).to eq(1)
          expect(Chouette::TimeTable.last.periods.count).to eq(1)

          period = Chouette::TimeTable.last.periods.first
          expect(period.range).to eq(Date.today.beginning_of_year..Date.today.end_of_year)
        end
      end
    end

    describe "{ time_table dates_excluded: Date.today }" do
      before do
        Chouette::Factory.create do
          time_table dates_excluded: Date.today
        end
      end

      it "should create TimeTable with default period" do
        Referential.last.switch do
          expect(Chouette::TimeTable.count).to eq(1)

          expect(Chouette::TimeTable.last.periods.count).to eq(1)
          period = Chouette::TimeTable.last.periods.first
          expect(period.range).to eq(Date.today.beginning_of_year..Date.today.end_of_year)
        end
      end

      it "should create TimeTable with specified excluded date" do
        Referential.last.switch do
          time_table = Chouette::TimeTable.last
          expect(time_table.dates.count).to eq(1)

          date = time_table.dates.first
          expect(date.in_out).to be_falsy
          expect(date.date).to eq(Date.today)
        end
      end
    end

    describe "{ time_table dates_included: Date.today }" do
      before do
        Chouette::Factory.create do
          time_table dates_included: Date.today
        end
      end

      it "should create TimeTable with default period" do
        Referential.last.switch do
          expect(Chouette::TimeTable.count).to eq(1)

          expect(Chouette::TimeTable.last.periods.count).to eq(1)
          period = Chouette::TimeTable.last.periods.first
          expect(period.range).to eq(Date.today.beginning_of_year..Date.today.end_of_year)
        end
      end

      it "should create TimeTable with specified included date" do
        Referential.last.switch do
          time_table = Chouette::TimeTable.last
          expect(time_table.dates.count).to eq(1)

          date = time_table.dates.first
          expect(date.in_out).to be_truthy
          expect(date.date).to eq(Date.today)
        end
      end
    end

  end

end
