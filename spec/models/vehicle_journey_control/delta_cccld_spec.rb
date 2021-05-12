
RSpec.describe VehicleJourneyControl::Delta, type: :model do
  let( :default_code ){ "3-VehicleJourney-3" }
  let( :factory ){ :vehicle_journey_control_delta }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
