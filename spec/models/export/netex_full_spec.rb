RSpec.describe Export::NetexFull, type: [:model, :with_exportable_referential] do

  let(:export) { create :netex_export_full, referential: referential, workbench: workbench, duration: 5}

  it 'should call a worker' do
    expect(NetexFullExportWorker).to receive(:perform_async_or_fail)
    export.run_callbacks(:commit)
  end
end
