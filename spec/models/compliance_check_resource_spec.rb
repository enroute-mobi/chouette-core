
RSpec.describe ComplianceCheckResource, type: :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_check_resource)).to be_valid
  end

  it { should validate_presence_of(:compliance_check_set) }
end
