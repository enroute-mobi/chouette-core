
RSpec.describe RouteControl::StopPointsInJourneyPattern, type: :model do
  let( :default_code ){ "3-Route-8" }
  let( :factory ){ :route_control_stop_points_in_journey_pattern }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
