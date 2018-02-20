RSpec.describe Import, type: :model do

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:file) }
  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:creator) }

  include ActionDispatch::TestProcess
  it { should allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file) }
  it { should_not allow_value(fixture_file_upload('users.json')).for(:file).with_message(I18n.t('errors.messages.extension_whitelist_error', extension: '"json"', allowed_types: "zip")) }

  let(:workbench_import) {netex_import.parent}
  let(:workbench_import_with_completed_steps) do
    build_stubbed(
      :workbench_import,
      total_steps: 2,
      current_step: 2
    )
  end

  let(:netex_import) do
    build_stubbed(
      :netex_import
    )
  end

  describe ".abort_old" do
    it "changes imports older than 4 hours to aborted" do
      Timecop.freeze(Time.now) do
        old_import = create(
          :workbench_import,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        current_import = create(:workbench_import, status: 'pending')

        Import.abort_old

        expect(current_import.reload.status).to eq('pending')
        expect(old_import.reload.status).to eq('aborted')
      end
    end

    it "doesn't work on imports with a `finished_status`" do
      Timecop.freeze(Time.now) do
        import = create(
          :workbench_import,
          status: 'successful',
          created_at: 4.hours.ago - 1.minute
        )

        Import.abort_old

        expect(import.reload.status).to eq('successful')
      end
    end

    it "only works on the caller type" do
      Timecop.freeze(Time.now) do
        workbench_import = create(
          :workbench_import,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        netex_import = create(
          :netex_import,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )

        NetexImport.abort_old

        expect(workbench_import.reload.status).to eq('pending')
        expect(netex_import.reload.status).to eq('aborted')
      end
    end
  end

  describe "#destroy" do
    it "must destroy all child imports" do
      netex_import = create(:netex_import)

      netex_import.parent.destroy

      expect(netex_import.parent).to be_destroyed
      expect(NetexImport.count).to eq(0)
    end

    it "must destroy all associated ImportMessages" do
      import = create(:import)
      create(:import_resource, import: import)

      import.destroy

      expect(ImportResource.count).to eq(0)
    end

    it "must destroy all associated ImportResources" do
      import = create(:import)
      create(:import_message, import: import)

      import.destroy

      expect(ImportMessage.count).to eq(0)
    end
  end

  describe "#notify_parent" do
    it "must call #child_change on its parent" do
      allow(netex_import).to receive(:update)

      expect(workbench_import).to receive(:child_change)

      netex_import.notify_parent
    end

    it "must update the :notified_parent_at field of the child import" do
      allow(workbench_import).to receive(:child_change)

      Timecop.freeze(DateTime.now) do
        expect(netex_import).to receive(:update).with(
          notified_parent_at: DateTime.now
        )

        netex_import.notify_parent
      end
    end
  end

  describe "#child_change" do
    it "calls #update_status" do
      allow(workbench_import).to receive(:update)

      expect(workbench_import).to receive(:update_status)
      workbench_import.child_change
    end

    it "calls #update_referentials" do
      allow(workbench_import).to receive(:update)

      expect(workbench_import).to receive(:update_referentials)
      workbench_import.child_change
    end
  end

  describe "#update_status" do
    shared_examples(
      "updates :status to failed when >=1 child has failing status"
    ) do |failure_status|
      it "updates :status to failed when >=1 child has failing status" do
        workbench_import = create(:workbench_import)
        create(
          :netex_import,
          parent: workbench_import,
          status: failure_status
        )

        workbench_import.update_status

        expect(workbench_import.status).to eq('failed')
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
      workbench_import = create(:workbench_import)
      imports = create_list(
        :netex_import,
        2,
        parent: workbench_import,
        status: 'successful'
      )

      workbench_import.update_status

      expect(workbench_import.status).to eq('successful')
    end

    it "updates :status to failed when any child has failed" do
      workbench_import = create(:workbench_import)
      [
        'failed',
        'successful'
      ].each do |status|
        create(
          :netex_import,
          parent: workbench_import,
          status: status
        )
      end

      workbench_import.update_status

      expect(workbench_import.status).to eq('failed')
    end

    it "updates :status to warning when any child has warning or successful" do
      workbench_import = create(:workbench_import)
      [
        'warning',
        'successful'
      ].each do |status|
        create(
          :netex_import,
          parent: workbench_import,
          status: status
        )
      end

      workbench_import.update_status

      expect(workbench_import.status).to eq('warning')
    end

    it "updates :ended_at to now when status is finished" do
      workbench_import = create(:workbench_import)
      create(
        :netex_import,
        parent: workbench_import,
        status: 'failed'
      )

      Timecop.freeze(Time.now) do
        workbench_import.update_status

        expect(workbench_import.ended_at).to eq(Time.now)
      end
    end
  end

  describe "#update_referentials" do
    it "doesn't update referentials if parent status isn't finished" do
      workbench_import = create(:workbench_import, status: 'pending')
      netex_import = create(:netex_import, parent: workbench_import)
      netex_import.referential.update(ready: false)

      workbench_import.update_referentials
      netex_import.referential.reload

      expect(netex_import.referential.ready).to be false
    end

    shared_examples(
      "makes child referentials `ready` when status is finished"
    ) do |finished_status|
      it "makes child referentials `ready` when status is finished" do
        workbench_import = create(:workbench_import, status: finished_status)
        netex_import = create(:netex_import, parent: workbench_import)
        netex_import.referential.update(ready: false)

        workbench_import.update_referentials
        netex_import.referential.reload

        expect(netex_import.referential.ready).to be true
      end
    end

    include_examples(
      "makes child referentials `ready` when status is finished",
      "successful"
    )
    include_examples(
      "makes child referentials `ready` when status is finished",
      "failed"
    )
    include_examples(
      "makes child referentials `ready` when status is finished",
      "aborted"
    )
    include_examples(
      "makes child referentials `ready` when status is finished",
      "canceled"
    )
  end
end
