require 'rails_helper'
RSpec.describe StopAreaReferentialSyncWorker, type: :worker do
  let!(:stop_area_referential_sync) { create :stop_area_referential_sync }

  it 'should call reflex synchronize on worker perform' do
    expect(Stif::ReflexSynchronization).to receive(:synchronize)
    StopAreaReferentialSyncWorker.new.perform(stop_area_referential_sync.id)
  end

  it 'should update stop_area_referential_sync started_at on worker perform' do
    StopAreaReferentialSyncWorker.new.perform(stop_area_referential_sync.id)
    expect(stop_area_referential_sync.reload.started_at).not_to be_nil
  end

  it 'should update stop_area_referential_sync ended_at on worker perform success' do
    StopAreaReferentialSyncWorker.new.perform(stop_area_referential_sync.id)
    expect(stop_area_referential_sync.reload.started_at).not_to be_nil
  end
end
