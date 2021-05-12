
RSpec.describe RoutingConstraintZoneControl::MaximumLength, type: :model do
  let( :default_code ){ "3-RoutingConstraint-2" }
  let( :factory ){ :routing_constraint_zone_control_maximum_length }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
