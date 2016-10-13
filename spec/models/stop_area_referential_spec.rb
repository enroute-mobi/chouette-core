require 'rails_helper'

RSpec.describe StopAreaReferential, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:stop_area_referential)).to be_valid
  end

  it { is_expected.to have_many(:stop_area_referential_syncs) }
end
