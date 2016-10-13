require 'rails_helper'

RSpec.describe StopAreaReferentialSync, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:stop_area_referential_sync)).to be_valid
  end

  it { is_expected.to belong_to(:stop_area_referential) }
  it { is_expected.to have_many(:stop_area_referential_sync_messages) }

  it 'should validate multiple sync instance' do
    pending  = create(:stop_area_referential_sync)
    multiple = build(:stop_area_referential_sync, stop_area_referential: pending.stop_area_referential)
    expect(multiple).to be_invalid
  end

  it 'should call StopAreaReferentialSyncWorker on create' do
    expect(StopAreaReferentialSyncWorker).to receive(:perform_async)
    create(:stop_area_referential_sync).run_callbacks(:commit)
  end

  describe 'states' do
    let(:stop_area_referential_sync) { create(:stop_area_referential_sync) }

    it 'should initialize with new state' do
      expect(stop_area_referential_sync.new?).to be_truthy
    end

    it 'should log pending state change' do
      expect(stop_area_referential_sync).to receive(:log_pending)
      stop_area_referential_sync.run
    end

    it 'should log successful state change' do
      expect(stop_area_referential_sync).to receive(:log_successful)
      stop_area_referential_sync.run
      stop_area_referential_sync.successful
    end

    it 'should log failed state change' do
      expect(stop_area_referential_sync).to receive(:log_failed)
      stop_area_referential_sync.run
      stop_area_referential_sync.failed
    end
  end
end
