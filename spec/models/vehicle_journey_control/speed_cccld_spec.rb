
RSpec.describe VehicleJourneyControl::Speed, type: :model do
  let( :default_code ){ "3-VehicleJourney-2" }
  let( :factory ){ :vehicle_journey_control_speed }

  it_behaves_like 'ComplianceControl Class Level Defaults'
end
