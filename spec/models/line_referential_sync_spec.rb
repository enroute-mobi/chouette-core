require 'rails_helper'

RSpec.describe LineReferentialSync, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:line_referential_sync)).to be_valid
  end

  it { is_expected.to belong_to(:line_referential) }
  it { is_expected.to have_many(:line_referential_sync_messages) }

  it 'should validate multiple sync instance' do
    pending  = create(:line_referential_sync)
    multiple = build(:line_referential_sync, line_referential: pending.line_referential)
    expect(multiple).to be_invalid
  end

  it 'should call LineReferentialSyncWorker on create' do
    expect(LineReferentialSyncWorker).to receive(:perform_async)
    create(:line_referential_sync).run_callbacks(:commit)
  end

  describe 'states' do
    let(:line_referential_sync) { create(:line_referential_sync) }

    it 'should initialize with new state' do
      expect(line_referential_sync.new?).to be_truthy
    end

    it 'should log pending state change' do
      expect(line_referential_sync).to receive(:log_pending)
      line_referential_sync.run
    end

    it 'should log successful state change' do
      expect(line_referential_sync).to receive(:log_successful)
      line_referential_sync.run
      line_referential_sync.successful
    end

    it 'should log failed state change' do
      expect(line_referential_sync).to receive(:log_failed)
      line_referential_sync.run
      line_referential_sync.failed
    end
  end
end
