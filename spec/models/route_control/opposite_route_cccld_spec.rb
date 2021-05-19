
RSpec.describe RouteControl::OppositeRoute, type: :model do
  let( :default_code ){ "3-Route-2" }
  let( :factory ){ :route_control_opposite_route }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
