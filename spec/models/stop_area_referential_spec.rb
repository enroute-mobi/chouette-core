RSpec.describe StopAreaReferential do
  it 'should have a valid factory' do
    expect(FactoryBot.build(:stop_area_referential)).to be_valid
  end

  it { is_expected.to have_many(:workbenches) }
  it { should validate_presence_of(:objectid_format) }
  it { should allow_value('').for(:registration_number_format) }
  it { should allow_value('X').for(:registration_number_format) }
  it { should allow_value('XXXXX').for(:registration_number_format) }
  it { should_not allow_value('123').for(:registration_number_format) }
  it { should_not allow_value('ABC').for(:registration_number_format) }
end
