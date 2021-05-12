
RSpec.describe VehicleJourneyControl::WaitingTime, type: :model do
  let( :default_code ){ "3-VehicleJourney-1" }
  let( :factory ){ :vehicle_journey_control_wating_time }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
