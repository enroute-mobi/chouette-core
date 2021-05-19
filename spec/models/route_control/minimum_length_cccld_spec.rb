
RSpec.describe RouteControl::MinimumLength, type: :model do
  let( :default_code ){ "3-Route-6" }
  let( :factory ){ :route_control_minimum_length }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
