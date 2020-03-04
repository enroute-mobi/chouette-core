RSpec.describe Export::NetexFull, type: [:model, :with_exportable_referential] do

  let!(:parent) { create :workgroup_export }
  let(:export) { create :netex_export_full, referential: referential, workbench: workbench, synchronous: synchronous, parent: parent}
  let(:synchronous){ false }
  it 'should call a worker' do
    expect{ export }.to change{ Delayed::Job.count }.by 1
  end

  describe '#worker_died' do

    it 'should set netex_full_export status to failed' do
      expect(export.status).to eq("new")
      export.worker_died
      expect(export.status).to eq("failed")
    end
  end

  context 'when synchronous' do
    let(:synchronous){ true }
    it 'should not call a worker' do
      allow_any_instance_of(Export::NetexFull).to receive(:upload_file) do |m|
        expect(m.owner).to eq export
      end

      expect{ export }.to_not change{ Delayed::Job.count }
    end

    context 'with journeys' do
      include_context 'with exportable journeys'

      it 'should create a new Netex document' do
        expect(Chouette::Netex::Document).to receive(:new).and_call_original
        expect_any_instance_of(Chouette::Netex::Document).to receive(:build)
        expect_any_instance_of(Chouette::Netex::Document).to receive(:to_xml)
        allow_any_instance_of(Export::NetexFull).to receive(:upload_file) do |m|
          expect(m.owner).to eq export
        end
        export
      end
    end
  end
end
