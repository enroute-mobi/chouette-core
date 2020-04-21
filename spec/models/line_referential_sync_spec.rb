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
    expect { create(:line_referential_sync) }.to change { Delayed::Job.count }.by 1
  end

  describe '#worker_died' do
    let(:line_referential_sync) { create(:line_referential_sync) }

    it 'should set line_referential_sync status to failed' do
      line_referential_sync.worker_died
      expect(line_referential_sync.status).to eq("failed")
    end
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

  context "#clean_previous_syncs" do
    it "should be called after create" do
      sync = build(:line_referential_sync)
      expect(sync).to receive(:clean_previous_syncs)
      sync.run_callbacks(:create)
    end

    it "should clean previous syncs" do
      line_ref = create(:line_referential)
      create_list(:line_referential_sync, 5, line_referential: line_ref, status: 'successful')

      expect(LineReferentialSync.count).to eq(5)
      LineReferentialSync.keep_syncs = 3
      line_ref.line_referential_syncs.last.clean_previous_syncs

      expect(LineReferentialSync.count).to eq(3)
    end
  end
end
