RSpec.describe ComplianceControl, type: :model do

  let(:compliance_control) { create :compliance_control }

  it 'should have a valid factory' do
    expect(compliance_control).to be_valid
  end

  it { should belong_to :compliance_control_set }
  it { should belong_to :compliance_control_block }

  it 'should validate_presence_of criticity' do
    compliance_control.criticity = nil
    expect(compliance_control).not_to be_valid
  end

  it 'should validate_presence_of name' do
    compliance_control.name = nil
    expect(compliance_control).not_to be_valid
  end

  it 'should validate_presence_of code' do
    compliance_control.code = nil
    expect(compliance_control).not_to be_valid
  end

  it 'should validate_presence_of origin_code' do
    compliance_control.origin_code = nil
    expect(compliance_control).not_to be_valid
  end

  #TODO dont know why the 'shortcuts' below to validates presence dont work
  # That's why we dont it 'manually'
  # it { should validate_presence_of :criticity }
  # it { should validate_presence_of :name }
  # it { should validate_presence_of :code }
  # it { should validate_presence_of :origin_code }

end
