
RSpec.describe JourneyPatternControl::Duplicates, type: :model do
  let( :default_code ){ "3-JourneyPattern-1" }
  let( :factory ){ :journey_pattern_control_duplicates }

  it_behaves_like 'ComplianceControl Class Level Defaults' 
end
