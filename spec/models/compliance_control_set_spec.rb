
RSpec.describe ComplianceControlSet, type: :model do
  it 'should have a valid factory' do
    expect(FactoryBot.build(:compliance_control_set)).to be_valid
  end

  it { should belong_to :organisation }
  it { should have_many(:compliance_controls).dependent(:destroy) }
  it { should have_many(:compliance_control_blocks).dependent(:destroy) }

  it { should validate_presence_of :name }
  
end
