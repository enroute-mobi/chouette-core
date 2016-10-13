require 'spec_helper'

RSpec.describe LineReferential, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:line_referential)).to be_valid
  end

  it { should validate_presence_of(:name) }
  it { is_expected.to have_many(:line_referential_syncs) }
  it { should validate_presence_of(:sync_interval) }
end
