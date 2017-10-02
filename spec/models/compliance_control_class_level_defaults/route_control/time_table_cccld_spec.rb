
RSpec.describe RouteControl::TimeTable, type: :model do
  let( :default_code ){ "3-VehicleJourney-4" }
  let( :factory ){ :route_control_time_table }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
