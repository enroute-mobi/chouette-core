
RSpec.describe RouteControl::OmnibusJourneyPattern, type: :model do
  let( :default_code ){ "3-Route-9" }
  let( :factory ){ :route_control_omnibus_journey_pattern }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
