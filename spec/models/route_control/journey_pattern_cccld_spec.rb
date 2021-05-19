
RSpec.describe RouteControl::JourneyPattern, type: :model do
  let( :default_code ){ "3-Route-3" }
  let( :factory ){ :route_control_journey_pattern }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
