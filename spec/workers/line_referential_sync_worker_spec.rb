require 'rails_helper'
RSpec.describe LineReferentialSyncWorker, type: :worker do
  let!(:line_referential_sync) { create :line_referential_sync }

  it 'should call codifline synchronize on worker perform' do
    expect(Stif::CodifLineSynchronization).to receive(:synchronize)
    LineReferentialSyncWorker.new.perform(line_referential_sync.id)
  end

  it 'should update line_referential_sync started_at on worker perform' do
    LineReferentialSyncWorker.new.perform(line_referential_sync.id)
    expect(line_referential_sync.reload.started_at).not_to be_nil
  end

  it 'should update line_referential_sync ended_at on worker perform success' do
    LineReferentialSyncWorker.new.perform(line_referential_sync.id)
    expect(line_referential_sync.reload.started_at).not_to be_nil
  end
end
