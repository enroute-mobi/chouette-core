RSpec.describe ComplianceCheckMessage, type: :model do
  it 'should have a valid factory' do
    expect(FactoryBot.build(:compliance_check_message)).to be_valid
  end

  it { should belong_to :compliance_check }
  it { should belong_to :compliance_check_resource }
  it { should belong_to :compliance_check_set }
end
