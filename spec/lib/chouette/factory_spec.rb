require "rails_helper"

RSpec.describe Chouette::Factory do

  it "should raise error when type isn't known" do
    expect {
      Chouette::Factory.create { dummy }
    }.to raise_error
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

  it "should create referential" do
    expect {
      Chouette::Factory.create { referential }
    }.to change { Referential.count }
  end

  it "should create Referential and VehicleJourney" do
    expect {
      Chouette::Factory.create do
        vehicle_journey
      end
    }.to change { Referential.count }

    Referential.last.switch do
      expect(Chouette::VehicleJourney.count).to eq(1)

      expect(Chouette::VehicleJourney.last.vehicle_journey_at_stops.count).to eq(3)
    end
  end

end
