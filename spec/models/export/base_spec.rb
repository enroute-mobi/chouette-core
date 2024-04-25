RSpec.describe Export::Base, type: :model do

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:creator) }

  describe ".purge_exports" do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it "removes files from exports older than 60 days" do
      file_purgeable = Timecop.freeze(60.days.ago) do
        export = create(
          :gtfs_export,
          workbench: workbench,
          file: File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))
        )
      end

      other_file_purgeable = Timecop.freeze(60.days.ago) do
        export = create(
          :gtfs_export,
          workbench: other_workbench,
          file: File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))
        )
      end

      Export::Gtfs.new(workbench: workbench).purge_exports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it "removes exports older than 90 days" do
      old_export = Timecop.freeze(90.days.ago) do
        create(:gtfs_export, workbench: workbench)
      end

      other_old_export = Timecop.freeze(90.days.ago) do
        create(:gtfs_export, workbench: other_workbench)
      end

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.to change {
        old_export.workbench.exports.purgeable.count
      }.from(1).to(0)

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.not_to change {
        old_export.workbench.exports.purgeable.count
      }
    end

    it 'keeps files used in Publication Apis' do
      old_export = Timecop.freeze(90.days.ago) do
        # We create TWO exports
        create(:gtfs_export, workbench: workbench)
        create(:gtfs_export, workbench: workbench)
      end

      create :publication_api_source, export: old_export, key: 'foo'
      create :publication_api_source, export: old_export, key: 'foo2'

      expect { Export::Gtfs.new(workbench: workbench).purge_exports }.to change {
        workbench.exports.count
      }.by -1
    end
  end

  describe "#destroy" do

    it "must destroy all associated Export::Messages" do
      export = create(:gtfs_export)
      create(:export_message, export: export)
      export.destroy

      expect(Export::Message.count).to eq(0)
    end
  end

  describe "#clean_exportables" do

    let(:export) { create(:gtfs_export) }
    before(:each) { export.exportables.create export: export }

    context 'when export is destroyed' do
      it 'must destroy all associated Exportables' do
        expect{ export.destroy }.to change { export.exportables.count }.from(1).to(0)
      end
    end

    context 'when export run' do
      it 'must destroy all associated Exportables' do
        expect{ export.run }.to change { export.exportables.count }.from(1).to(0)
      end
    end
  end

  describe "#notify_publication" do
    let(:publication) { create(:publication) }
    let(:gtfs_export) { create(:gtfs_export, publication: publication) }

    context "when export is finished" do
      before do
        gtfs_export.status = "successful"
        gtfs_export.notified_parent_at = nil
      end

      it "must call #child_change on its parent" do
        expect(publication).to receive(:child_change)
        gtfs_export.notified_parent_at = nil
        gtfs_export.notify_publication
      end

      it "must update the :notified_parent_at field of the child export" do
        Timecop.freeze(Time.now) do
          gtfs_export.notify_publication
          expect(gtfs_export.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')
          expect(gtfs_export.reload.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')
        end
      end
    end

    context "when export is not finished" do
      before do
        gtfs_export.status = "running"
        gtfs_export.notified_parent_at = nil
      end

      it "must not call #child_change on its parent" do
        allow(gtfs_export).to receive(:update)

        expect(gtfs_export).to_not receive(:child_change)
        gtfs_export.notify_publication
      end

      it "must keep nil the :notified_parent_at field of the child export" do
        gtfs_export.notify_publication
        expect(gtfs_export.notified_parent_at).to be_nil
      end

    end
  end

  context "#user_file" do

    before do
      subject.name = "Dummy Export Example"
    end

    it 'uses a parameterized version of the Export name as base name' do
      expect(subject.user_file.basename).to eq("dummy-export-example")
    end

    it 'uses the Export content_type' do
      expect(subject.user_file.content_type).to eq(subject.content_type)
    end

    it 'uses the Export file_extension' do
      expect(subject.user_file.extension).to eq(subject.send(:file_extension))
    end

  end

  context "#has_feature?" do
    subject { export.has_feature?(feature) }

    let(:export) { Export::Base.new }
    let(:feature) { "dummy"}

    let(:organisation) { Organisation.new }

    context "when a Workbench is defined" do
      before { export.organisation = organisation }
      context "when the Workbench organisation has the feature" do
        before { organisation.features << feature }
        it { is_expected.to be_truthy }
      end
      context "when the Workbench organisation hasn't the feature" do
        it { is_expected.to be_falsy }
      end
    end

    context "when only the Workgroup is defined" do
      before { export.workgroup = Workgroup.new(owner: organisation) }
      context "when the Workgroup organisation has the feature" do
        before { organisation.features << feature }
        it { is_expected.to be_truthy }
      end
      context "when the Workgroup organisation hasn't the feature" do
        it { is_expected.to be_falsy }
      end
    end
  end

end
