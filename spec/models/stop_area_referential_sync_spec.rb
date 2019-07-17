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
    expect { create(:stop_area_referential_sync) }.to change{ Delayed::Job.count }.by 1
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

   context "#clean_previous_syncs" do
    it "should be called after create" do
      sync = build(:stop_area_referential_sync)
      expect(sync).to receive(:clean_previous_syncs)
      sync.run_callbacks(:create)
    end

    it "should clean previous syncs" do
      stop_area_ref = create(:stop_area_referential)
      previous = create_list(:stop_area_referential_sync, 5, stop_area_referential: stop_area_ref, status: 'successful')

      expect(StopAreaReferentialSync.count).to eq(5)
      StopAreaReferentialSync.keep_syncs = 3
      stop_area_ref.stop_area_referential_syncs.last.clean_previous_syncs

      expect(StopAreaReferentialSync.count).to eq(3)
      (0..1).each do |i|
        expect { previous[i].reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
      expect(previous[2].reload).to_not be_nil
      (2..4).each do |i|
        expect(previous[i].reload).to_not be_nil
      end
    end
  end
end
