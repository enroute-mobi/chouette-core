
RSpec.describe LineReferentialSyncMessage, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryBot.build(:line_referential_sync_message)).to be_valid
  end

  it { is_expected.to belong_to(:line_referential_sync) }
  it { is_expected.to validate_presence_of(:criticity) }
end
