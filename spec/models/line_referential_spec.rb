RSpec.describe LineReferential, type: :model do
  it 'should have a valid factory' do
    expect(FactoryBot.build(:line_referential)).to be_valid
  end

  it { should validate_presence_of(:name) }
  it { is_expected.to have_many(:line_referential_syncs) }
  it { is_expected.to have_many(:workbenches) }
  it { should validate_presence_of(:sync_interval) }
  it { should validate_presence_of(:objectid_format) }

end
