
RSpec.describe VehicleJourneyControl::TimeTable, type: :model do
  let( :default_code ){ "3-VehicleJourney-4" }
  let( :factory ){ :vehicle_journey_control_time_table }

  it_behaves_like 'ComplianceControl Class Level Defaults'
end
