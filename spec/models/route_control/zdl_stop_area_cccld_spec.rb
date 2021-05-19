
RSpec.describe RouteControl::ZDLStopArea, type: :model do
  let( :default_code ){ "3-Route-1" }
  let( :factory ){ :route_control_zdl_stop_area }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
