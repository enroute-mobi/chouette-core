RSpec.describe Export::Base, type: :model do

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:creator) }

  include ActionDispatch::TestProcess
  it { should allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file) }
  it { should_not allow_value(fixture_file_upload('reflex_updated.xml')).for(:file).with_message(I18n.t('errors.messages.extension_whitelist_error', extension: '"xml"', allowed_types: "zip, csv, json")) }

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
      create(:export_resource, export: export)

      export.destroy

      expect(Export::Resource.count).to eq(0)
    end

    it "must destroy all associated Export::Resources" do
      export = create(:gtfs_export)
      create(:export_message, export: export)

      export.destroy

      expect(Export::Message.count).to eq(0)
    end
  end

  describe "#notify_parent" do
    let(:publication) { create(:publication) }
    let(:gtfs_export) { create(:gtfs_export, parent: publication) }

    context "when export is finished" do
      before do
        gtfs_export.status = "successful"
        gtfs_export.notified_parent_at = nil
      end

      it "must call #child_change on its parent" do
        expect(publication).to receive(:child_change)
        gtfs_export.notified_parent_at = nil
        gtfs_export.notify_parent
      end

      it "must update the :notified_parent_at field of the child export" do
        Timecop.freeze(Time.now) do
          gtfs_export.notify_parent
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
        gtfs_export.notify_parent
      end

      it "must keep nil the :notified_parent_at field of the child export" do
        gtfs_export.notify_parent
        expect(gtfs_export.notified_parent_at).to be_nil
      end

    end
  end

  describe "#update_status" do

    it "updates :ended_at to now when status is finished" do
      gtfs_export = create(:gtfs_export)
      allow(gtfs_export).to receive(:compute_new_status).and_return('failed')
      Timecop.freeze(Time.now) do
        gtfs_export.update_status
        expect(gtfs_export.ended_at).to eq(Time.now)
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

end
