require 'rails_helper'

RSpec.describe StopAreaReferentialSyncMessage, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:stop_area_referential_sync_message)).to be_valid
  end
  it { is_expected.to belong_to(:stop_area_referential_sync) }
  it { is_expected.to validate_presence_of(:criticity) }
end
