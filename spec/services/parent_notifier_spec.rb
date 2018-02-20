RSpec.describe ParentNotifier do
  let(:workbench_import) { create(:workbench_import) }

  describe ".notify_when_finished" do
    it "calls #notify_parent on finished imports" do
      workbench_import = build_stubbed(:workbench_import)

      finished_statuses = [:failed, :successful, :aborted, :canceled]
      netex_imports = []

      finished_statuses.each do |status|
        netex_imports << build_stubbed(
          :netex_import,
          parent: workbench_import,
          status: status
        )
      end

      netex_imports.each do |netex_import|
        expect(netex_import).to receive(:notify_parent)
      end

      ParentNotifier.new(Import).notify_when_finished(netex_imports)
    end

    it "doesn't call #notify_parent if its `notified_parent_at` is set" do
      netex_import = create(
        :netex_import,
        parent: workbench_import,
        status: :failed,
        notified_parent_at: DateTime.now
      )

      expect(netex_import).not_to receive(:notify_parent)

      ParentNotifier.new(Import).notify_when_finished
    end
  end

  describe ".objects_pending_notification" do
    it "includes imports with a parent and `notified_parent_at` unset" do
      netex_import = create(
        :netex_import,
        parent: workbench_import,
        status: :successful,
        notified_parent_at: nil
      )

      expect(
        ParentNotifier.new(Import).objects_pending_notification
      ).to eq([netex_import])
    end

    it "doesn't include imports without a parent" do
      create(:import, parent: nil)

      expect(
        ParentNotifier.new(Import).objects_pending_notification
      ).to be_empty
    end

    it "doesn't include imports that aren't finished" do
      [:new, :pending, :running].each do |status|
        create(
          :netex_import,
          parent: workbench_import,
          status: status,
          notified_parent_at: nil
        )
      end

      expect(
        ParentNotifier.new(Import).objects_pending_notification
      ).to be_empty
    end

    it "doesn't include imports that have already notified their parent" do
      create(
        :netex_import,
        parent: workbench_import,
        status: :successful,
        notified_parent_at: DateTime.now
      )

      expect(
        ParentNotifier.new(Import).objects_pending_notification
      ).to be_empty
    end
  end
end
