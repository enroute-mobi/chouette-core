RSpec.describe Export::Base, type: :model do

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:creator) }

  include ActionDispatch::TestProcess
  it { should allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file) }
  it { should_not allow_value(fixture_file_upload('reflex_updated.xml')).for(:file).with_message(I18n.t('errors.messages.extension_whitelist_error', extension: '"xml"', allowed_types: "zip, csv, json")) }

  let(:workgroup_export) { netex_export.parent }
  let(:workgroup_export_with_completed_steps) do
    build_stubbed(
      :workgroup_export,
      total_steps: 2,
      current_step: 2
    )
  end

  let(:netex_export) { create(:netex_export, :with_parent) }

  describe ".purge_exports" do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it "removes files from exports older than 7 days" do
      file_purgeable = Timecop.freeze(7.days.ago) do
        export = create(
          :workgroup_export,
          workbench: workbench,
          file: File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))
        )
      end

      other_file_purgeable = Timecop.freeze(7.days.ago) do
        export = create(
          :workgroup_export,
          workbench: other_workbench,
          file: File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json'))
        )
      end

      Export::Workgroup.new(workbench: workbench).purge_exports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it "removes exports older than 90 days" do
      old_export = Timecop.freeze(90.days.ago) do
        create(:workgroup_export, workbench: workbench)
      end

      other_old_export = Timecop.freeze(90.days.ago) do
        create(:workgroup_export, workbench: other_workbench)
      end

      expect { Export::Workgroup.new(workbench: workbench).purge_exports }.to change {
        old_export.workbench.exports.purgeable.count
      }.from(1).to(0)

      expect { Export::Workgroup.new(workbench: workbench).purge_exports }.not_to change {
        old_export.workbench.exports.purgeable.count
      }
    end

    it 'keeps files used in Publication Apis' do
      old_export = Timecop.freeze(90.days.ago) do
        # We create TWO exports
        create(:workgroup_export, workbench: workbench)
        create(:workgroup_export, workbench: workbench)
      end

      create :publication_api_source, export: old_export
      create :publication_api_source, export: old_export

      expect { Export::Workgroup.new(workbench: workbench).purge_exports }.to change {
        workbench.exports.count
      }.by -1
    end
  end

  describe ".abort_old" do
    it "changes exports older than 4 hours to aborted" do
      Timecop.freeze(Time.now) do
        old_export = create(
          :workgroup_export,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        current_export = create(:workgroup_export, status: 'pending')

        Export::Base.abort_old

        expect(current_export.reload.status).to eq('pending')
        expect(old_export.reload.status).to eq('aborted')
      end
    end

    it "doesn't work on exports with a `finished_status`" do
      Timecop.freeze(Time.now) do
        export = create(
          :workgroup_export,
          status: 'successful',
          created_at: 4.hours.ago - 1.minute
        )

        Export::Base.abort_old

        expect(export.reload.status).to eq('successful')
      end
    end

    it "only works on the caller type" do
      Timecop.freeze(Time.now) do
        workgroup_export = create(
          :workgroup_export,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        netex_export = create(
          :netex_export,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )

        Export::Netex.abort_old

        expect(workgroup_export.reload.status).to eq('pending')
        expect(netex_export.reload.status).to eq('aborted')
      end
    end
  end

  describe "#destroy" do
    it "must destroy all child exports" do
      netex_export = create(:netex_export, :with_parent)

      netex_export.parent.destroy

      expect(netex_export.parent).to be_destroyed
      expect(Export::Netex.count).to eq(0)
    end

    it "must destroy all associated Export::Messages" do
      export = create(:netex_export)
      create(:export_resource, export: export)

      export.destroy

      expect(Export::Resource.count).to eq(0)
    end

    it "must destroy all associated Export::Resources" do
      export = create(:netex_export)
      create(:export_message, export: export)

      export.destroy

      expect(Export::Message.count).to eq(0)
    end
  end

  describe "#notify_parent" do
    context "when export is finished" do
      before do
        netex_export.status = "successful"
        netex_export.notified_parent_at = nil
      end

      it "must call #child_change on its parent" do
        allow(netex_export).to receive(:update)

        expect(workgroup_export).to receive(:child_change)
        netex_export.notified_parent_at = nil
        netex_export.notify_parent
      end

      it "must update the :notified_parent_at field of the child export" do
        allow(workgroup_export).to receive(:child_change)

        Timecop.freeze(Time.now) do
          netex_export.notify_parent
          expect(netex_export.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')
          expect(netex_export.reload.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%3N')
        end
      end
    end

    context "when export is not finished" do
      before do
        netex_export.status = "running"
        netex_export.notified_parent_at = nil
      end

      it "must not call #child_change on its parent" do
        allow(netex_export).to receive(:update)

        expect(workgroup_export).to_not receive(:child_change)
        netex_export.notify_parent
      end

      it "must keep nil the :notified_parent_at field of the child export" do
        netex_export.notify_parent
        expect(netex_export.notified_parent_at).to be_nil
      end

    end
  end

  describe "#child_change" do
    it "calls #update_status" do
      allow(workgroup_export).to receive(:update)

      expect(workgroup_export).to receive(:update_status)
      workgroup_export.child_change
    end
  end

  describe "#update_status" do
    shared_examples(
      "updates :status to failed when >=1 child has failing status"
    ) do |failure_status|
      it "updates :status to failed when >=1 child has failing status" do
        workgroup_export = create(:workgroup_export)
        create(
          :netex_export,
          parent: workgroup_export,
          status: failure_status
        )

        workgroup_export.update_status

        expect(workgroup_export.status).to eq('failed')
      end
    end

    include_examples(
      "updates :status to failed when >=1 child has failing status",
      "failed"
    )
    include_examples(
      "updates :status to failed when >=1 child has failing status",
      "aborted"
    )
    include_examples(
      "updates :status to failed when >=1 child has failing status",
      "canceled"
    )

    it "updates :status to successful when all children are successful" do
      workgroup_export = create(:workgroup_export)
      exports = create_list(
        :netex_export,
        2,
        parent: workgroup_export,
        status: 'successful'
      )

      workgroup_export.update_status

      expect(workgroup_export.status).to eq('successful')
    end

    it "updates :status to failed when any child has failed" do
      workgroup_export = create(:workgroup_export)
      [
        'failed',
        'successful'
      ].each do |status|
        create(
          :netex_export,
          parent: workgroup_export,
          status: status
        )
      end

      workgroup_export.update_status

      expect(workgroup_export.status).to eq('failed')
    end

    it "updates :status to warning when any child has warning or successful" do
      workgroup_export = create(:workgroup_export)
      [
        'warning',
        'successful'
      ].each do |status|
        create(
          :netex_export,
          parent: workgroup_export,
          status: status
        )
      end

      workgroup_export.update_status

      expect(workgroup_export.status).to eq('warning')
    end

    it "updates :ended_at to now when status is finished" do
      workgroup_export = create(:workgroup_export)
      create(
        :netex_export,
        parent: workgroup_export,
        status: 'failed'
      )

      Timecop.freeze(Time.now) do
        workgroup_export.update_status

        expect(workgroup_export.ended_at).to eq(Time.now)
      end
    end
  end
end
