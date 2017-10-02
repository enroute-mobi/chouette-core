
RSpec.describe LineControl::Route, type: :model do
  let( :default_code ){ "3-Line-1" }
  let( :factory ){ :line_control_route }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
