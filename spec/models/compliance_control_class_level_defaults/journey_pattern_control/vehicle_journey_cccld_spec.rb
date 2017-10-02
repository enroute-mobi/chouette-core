
RSpec.describe JourneyPatternControl::VehicleJourney, type: :model do
  let( :default_code ){ "3-JourneyPattern-2" }
  let( :factory ){ :journey_pattern_control_vehicle_journey }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
