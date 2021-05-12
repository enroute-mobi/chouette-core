
RSpec.describe RoutingConstraintZoneControl::UnactivatedStopPoint, type: :model do
  let( :default_code ){ "3-RoutingConstraint-1" }
  let( :factory ){ :routing_constraint_zone_control_unactivated_stop_point }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
