RSpec.describe Export::NetexFull, type: [:model, :with_exportable_referential] do

  let(:export) { create :netex_export_full, referential: referential, workbench: workbench, synchronous: synchronous}
  let(:synchronous){ false }
  it 'should call a worker' do
    expect(NetexFullExportWorker).to receive(:perform_async_or_fail)
    export.run_callbacks(:commit)
  end

  context 'when synchronous' do
    let(:synchronous){ true }
    it 'should not call a worker' do
      expect(NetexFullExportWorker).to_not receive(:perform_async_or_fail)
      export.run_callbacks(:commit)
    end

    context 'with journeys' do
      include_context 'with exportable journeys'

      it 'should create a new Netex document' do
        expect(Chouette::Netex::Document).to receive(:new).and_call_original
        expect_any_instance_of(Chouette::Netex::Document).to receive(:build)
        expect_any_instance_of(Chouette::Netex::Document).to receive(:to_xml)
        expect(export).to receive :upload_file
        export.run_callbacks(:commit)
      end
    end
  end
end
