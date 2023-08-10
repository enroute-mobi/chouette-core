RSpec.describe Import::Base, type: :model do

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it { should enumerize(:status).in("aborted", "canceled", "failed", "new", "pending", "running", "successful", "warning") }

  it { should validate_presence_of(:file) }
  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:creator) }

  include ActionDispatch::TestProcess
  it { should allow_value(fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip')).for(:file) }
  it { should_not allow_value(fixture_file_upload('invalid_version.json')).for(:file).with_message(I18n.t('errors.messages.extension_whitelist_error', extension: '"json"', allowed_types: "zip")) }

  let(:workbench_import) {netex_import.parent}
  let(:workbench_import_with_completed_steps) do
    build_stubbed(
      :workbench_import,
      total_steps: 2,
      current_step: 2
    )
  end

  let(:netex_import) do
    create(
      :netex_import
    )
  end

  describe ".maximum_runtime" do
    it "should use CHOUETTE_IMPORT_MAX_RUN_TIME if exists" do
      allow(SmartEnv).to receive(:fetch).with("CHOUETTE_IMPORT_MAX_RUN_TIME").and_return(4)
      expect(Import::Base.maximum_runtime).to eq(4.hours)
    end

    it "should use DELAYED_JOB_MAX_RUN_TIME by default" do
      expect(Import::Base.maximum_runtime).to eq(24.hours)
    end

  end

  context "when CHOUETTE_IMPORT_MAX_RUN_TIME is set" do

    before do
      allow(SmartEnv).to receive(:fetch).with("CHOUETTE_IMPORT_MAX_RUN_TIME").and_return(4)
    end

    describe ".abort_old" do
      it "changes imports older than 4 hours to aborted" do
        old_import = create(
          :workbench_import,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        current_import = create(:workbench_import, status: 'pending')

        Import::Base.abort_old

        expect(current_import.reload.status).to eq('running')
        expect(old_import.reload.status).to eq('aborted')
      end

      it "doesn't work on imports with a `finished_status`" do
        import = create(
          :workbench_import,
          created_at: 4.hours.ago - 1.minute
        )
        import.update status: 'successful'

        Import::Base.abort_old
        expect(import.reload.status).to eq('successful')
      end

      it "only works on the caller type" do
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

        Import::Netex.abort_old

        expect(workbench_import.reload.status).to eq('running')
        expect(netex_import.reload.status).to eq('aborted')
      end
    end
  end

  describe "#destroy" do
    it "must destroy all child imports" do
      netex_import = create(:netex_import)
      netex_import.parent.reload

      netex_import.parent.destroy

      expect(netex_import.parent).to be_destroyed
      expect(Import::Netex.count).to eq(0)
    end

    it "must destroy all associated Import::Messages" do
      import = create(:import)
      create(:import_resource, import: import)

      import.destroy

      expect(Import::Resource.count).to eq(0)
    end

    it "must destroy all associated Import::Resources" do
      import = create(:import)
      create(:import_message, import: import)

      import.destroy

      expect(Import::Message.count).to eq(0)
    end
  end

  describe "#notify_parent" do
    context "when import is finished" do
      before do
        netex_import.status = "successful"
        netex_import.notified_parent_at = nil
      end

      it "must call #child_change on its parent" do
        allow(netex_import).to receive(:update)

        expect(workbench_import).to receive(:child_change)
        netex_import.notify_parent
      end

      it "must update the :notified_parent_at field of the child import" do
        allow(workbench_import).to receive(:child_change)
        netex_import.notify_parent
        expect(netex_import.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M')
        expect(netex_import.reload.notified_parent_at.utc.strftime('%Y-%m-%d %H:%M')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M')
      end
    end

    context "when import is not finished" do
      before do
        netex_import.status = "running"
        netex_import.notified_parent_at = nil
      end

      it "must not call #child_change on its parent" do
        allow(netex_import).to receive(:update)

        expect(workbench_import).to_not receive(:child_change)
        netex_import.notify_parent
      end

      it "must keep nil the :notified_parent_at field of the child import" do
        netex_import.notify_parent
        expect(netex_import.notified_parent_at).to be_nil
      end

    end
  end

  describe "#child_change" do
    it "calls #update_status" do
      allow(workbench_import).to receive(:update)

      expect(workbench_import).to receive(:update_status)
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
          notified_parent_at: Date.today,
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
        notified_parent_at: Date.today,
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
          notified_parent_at: Date.today,
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
          notified_parent_at: Date.today,
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
        notified_parent_at: Date.today,
        status: 'failed'
      )

      workbench_import.update_status
      expect(workbench_import.ended_at.utc.strftime('%Y-%m-%d %H:%M')).to eq Time.now.utc.strftime('%Y-%m-%d %H:%M')
    end
  end
end
