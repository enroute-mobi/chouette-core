
RSpec.describe GenericAttributeControl::Uniqueness, type: :model do
  let( :default_code ){ "3-Generic-3" }
  let( :factory ){ :generic_attribute_control_uniqueness }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
  it_behaves_like 'has target attribute'
end
