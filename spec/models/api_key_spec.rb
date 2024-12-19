
RSpec.describe ApiKey, type: :model do
  subject { create(:api_key) }

  it { is_expected.to belong_to(:workbench).required }
  it { should validate_uniqueness_of :token }


  it 'should have a valid factory' do
    expect(build(:api_key)).to be_valid
  end
end
