
RSpec.describe RoutingConstraintZoneControl::MinimumLength, type: :model do
  let( :default_code ){ "3-ITL-3" }
  let( :factory ){ :routing_constraint_zone_control_minimum_length }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
