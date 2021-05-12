
RSpec.describe VehicleJourneyControl::VehicleJourneyAtStops, type: :model do
  let( :default_code ){ "3-VehicleJourney-5" }
  let( :factory ){ :vehicle_journey_control_vehicle_journey_at_stops }

  it_behaves_like 'ComplianceControl Class Level Defaults'
end
