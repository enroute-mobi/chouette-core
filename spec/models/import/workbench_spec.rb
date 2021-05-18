
RSpec.describe Import::Workbench do

  let(:referential) do
    create :referential do |referential|
      referential.line_referential.objectid_format = "netex"
      referential.stop_area_referential.objectid_format = "netex"
    end
  end

  let(:new_referential){ create :referential }

  let(:workbench) do
    create :workbench do |workbench|
      workbench.line_referential.objectid_format = "netex"
      workbench.stop_area_referential.objectid_format = "netex"
    end
  end

  let(:options){
    {}
  }

  let(:import) {
    Import::Workbench.create workbench: workbench, name: "test", creator: "Albator", file: open_fixture("google-sample-feed.zip"), options: options
  }

  let(:import_workbench) {
    create :workbench_import, workbench: workbench
  }

  context '#children_status' do
    it 'should return failed if a child has a failed status' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "failed", notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "warning", notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'failed'
    end

    it 'should return warning if one child has a warning and not failed status' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "warning", notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'warning'
    end

    it 'should return successful if children have successful statuses' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "successful", notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'successful'
    end

    it 'should return running if children have not finished' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "successful", notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: "pending", notified_parent_at: nil)
      expect(import_workbench.children_status).to eq 'running'
    end
  end

  context '#compliance_check_sets_status' do
    it 'should return failed if a compliance_check_set has a failed status' do
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "failed", notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "warning", notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'failed'
    end

    it 'should return warning if one compliance_check_set has a warning and not failed status' do
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "warning", notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'warning'
    end

    it 'should return successful if compliance_check_sets have successful statuses' do
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "successful", notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "successful", notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'successful'
    end

    it 'should return running if compliance_check_sets have not finished' do
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "successful", notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: "Import::Workbench", workbench: workbench, status: "pending", notified_parent_at: nil)
      expect(import_workbench.compliance_check_sets_status).to eq 'running'
    end
  end

  context '#compute_new_status' do
    it 'should return failed if compliance_check_sets_status or children_status is failed' do
      allow(import_workbench).to receive(:compliance_check_sets_status).and_return 'failed'
      allow(import_workbench).to receive(:children_status).and_return 'warning'
      expect(import_workbench.compute_new_status).to eq 'failed'
    end

    it 'should return warning if compliance_check_sets_status or children_status is warning' do
      allow(import_workbench).to receive(:compliance_check_sets_status).and_return 'warning'
      allow(import_workbench).to receive(:children_status).and_return 'successful'
      expect(import_workbench.compute_new_status).to eq 'warning'
    end

    it 'should return successful if compliance_check_sets_status and children_status are successful' do
      allow(import_workbench).to receive(:compliance_check_sets_status).and_return 'successful'
      allow(import_workbench).to receive(:children_status).and_return 'successful'
      expect(import_workbench.compute_new_status).to eq 'successful'
    end

    it 'should return running if compliance_check_sets_status or children_status is running' do
      allow(import_workbench).to receive(:compliance_check_sets_status).and_return 'running'
      allow(import_workbench).to receive(:children_status).and_return 'successful'
      expect(import_workbench.compute_new_status).to eq 'running'
    end

  end

  context '#file_type' do
    let(:filename) { 'google-sample-feed.zip' }
    let(:import) {
      Import::Workbench.new workbench: workbench, name: "test", creator: "Albator", file: open_fixture(filename), options: options
    }
    context 'with a GTFS file' do
      it 'should return :gtfs' do
        expect(import.file_type).to eq :gtfs
      end
    end

    context 'with a NETEX file' do
      let(:filename) { 'OFFRE_TRANSDEV_2017030112251.zip' }
      it 'should return :netex' do
        expect(import.file_type).to eq :netex
      end
    end

    context 'with a Neptune file' do
      let(:filename) { 'fake_neptune.zip' }
      it 'should return :neptune' do
        expect(import.file_type).to eq :neptune
      end
    end

    context 'with a malformed file' do
      let(:filename) { 'malformed_import_file.zip' }
      it 'should return nil' do
        expect(import.file_type).to be_nil
      end
    end

    context 'with import_type restriction' do
      before { import.workgroup.import_types = ["Import::Gtfs"] }

      context 'with a GTFS file' do
        it 'should return :gtfs' do
          expect(import.file_type).to eq :gtfs
        end
      end

      context 'with a NETEX file' do
        let(:filename) { 'OFFRE_TRANSDEV_2017030112251.zip' }
        it 'should return nil' do
          expect(import.file_type).to be_nil
        end
      end
    end
  end


  describe "#done!" do
    context "when flag_urgent option is selected" do
      before { import.flag_urgent = true }
      it "flag referentials as urgent" do
        expect(import).to receive(:flag_refentials_as_urgent)
        import.done! true
      end
    end

    context "when flag_urgent option isn't selected" do
      before { import.flag_urgent = false }
      it "doesn't flag referentials as urgent" do
        expect(import).to_not receive(:flag_refentials_as_urgent)
        import.done! true
      end
    end

    context "when automatic_merge option is selected" do
      before { import.automatic_merge = true }
      it "create automatic merge" do
        expect(import).to receive(:create_automatic_merge)
        import.done! true
      end
    end

    context "when automatic_merge option isn't selected" do
      before { import.automatic_merge = false }
      it "doesn't create automatic merge" do
        expect(import).to_not receive(:create_automatic_merge)
        import.done! true
      end
    end

    context "when archive_on_fail option is selected" do
      before { import.archive_on_fail = true }
      it "automaticaly archive referentials" do
        expect(import).to receive(:archive_referentials)
        import.done! false
      end
    end

    context "when archive_on_fail option isn't selected" do
      before { import.archive_on_fail = false }
      it "doesn't automaticaly archive referentials" do
        expect(import).to_not receive(:archive_referentials)
        import.done! false
      end
    end
  end

  describe "#flag_refentials_as_urgent" do

    # Time.now.round simplifies Time comparaison in specs
    around { |example| Timecop.freeze(Time.now.round) { example.run } }

    let(:referential) do
      # FIXME Use Chouette.create to create consistent models
      create(:referential).tap do |referential|
        create(:referential_metadata, referential: referential)
      end
    end

    before { import.resources.create referential: referential }

    it "flag referential metadatas as urgent" do
      expect do
        import.flag_refentials_as_urgent
      end.to change { referential.reload.flagged_urgent_at }.from(nil).to(Time.now)
    end

  end

  describe "#create_automatic_merge" do

    before { import.resources.create referential: new_referential }

    it "create a new Merge" do
      expect{ import.create_automatic_merge }.to change{ Merge.count }.by(1)
    end

    describe "new Merge" do

      subject(:merge) { import.create_automatic_merge }

      it "has the same creator than the Import" do
        expect(merge.creator).to eq(import.creator)
      end
      it "has the same user than the Import" do
        import.user = User.new
        expect(merge.user).to eq(import.user)
      end
      it "has the same workbench than the Import" do
        expect(merge.workbench).to eq(import.workbench)
      end
      it "has the same referentials than the Import" do
        expect(merge.referentials).to eq(import.referentials)
      end
      it "has the same notification_target than the Import" do
        expect(merge.notification_target).to eq(import.notification_target)
      end

    end

  end

end
