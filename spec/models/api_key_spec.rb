
RSpec.describe ApiKey, type: :model do
  subject { create(:api_key) }

  it { should validate_presence_of :workbench }
  it { should validate_uniqueness_of :token }


  it 'should have a valid factory' do
    expect(build(:api_key)).to be_valid
  end
end
