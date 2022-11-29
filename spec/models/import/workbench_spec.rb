RSpec.describe Import::Workbench do
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  let(:options) { {} }

  let(:import_workbench) { create :workbench_import, workbench: workbench, referential: referential }

  context '#children_status' do
    let(:context) do
      Chouette.create do
        referential
      end
    end

    it 'should return failed if a child has a failed status' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'failed',
                            notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'warning',
                            notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'successful',
                            notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'failed'
    end

    it 'should return warning if one child has a warning and not failed status' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'warning',
                            notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'successful',
                            notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'warning'
    end

    it 'should return successful if children have successful statuses' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'successful',
                            notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'successful',
                            notified_parent_at: Date.today)
      expect(import_workbench.children_status).to eq 'successful'
    end

    it 'should return running if children have not finished' do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'successful',
                            notified_parent_at: Date.today)
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'pending', notified_parent_at: nil)
      expect(import_workbench.children_status).to eq 'running'
    end
  end

  context '#compliance_check_sets_status' do
    let(:context) do
      Chouette.create do
        referential
      end
    end

    it 'should return failed if a compliance_check_set has a failed status' do
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'failed', notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'warning', notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'successful', notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'failed'
    end

    it 'should return warning if one compliance_check_set has a warning and not failed status' do
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'warning', notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'successful', notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'warning'
    end

    it 'should return successful if compliance_check_sets have successful statuses' do
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'successful', notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'successful', notified_parent_at: Date.today)
      expect(import_workbench.compliance_check_sets_status).to eq 'successful'
    end

    it 'should return running if compliance_check_sets have not finished' do
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'successful', notified_parent_at: Date.today)
      create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                    status: 'pending', notified_parent_at: nil)
      expect(import_workbench.compliance_check_sets_status).to eq 'running'
    end
  end

  context '#processed_status' do
    let(:context) do
      Chouette.create do
        referential
        processing_rule
      end
    end
    let(:netex_import) do
      create(:netex_import, parent: import_workbench, workbench: workbench, status: 'failed',
                            notified_parent_at: Date.today)
    end
    let(:control_list) { Control::List.create name: 'Control List 1', workbench: workbench }
    let(:macro_list) { Macro::List.create name: 'Macro List 1', workbench: workbench }
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench, name: 'Control',
                                original_control_list: control_list, creator: 'Webservice'
    end
    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: workbench, name: 'Macro',
                              original_macro_list: macro_list, creator: 'Webservice'
    end

    before(:each) do
      netex_import.processings.create(processed: control_list_run, processing_rule: context.processing_rule,
                                      workbench: workbench)
      netex_import.processings.create(processed: macro_list_run, processing_rule: context.processing_rule,
                                      workbench: workbench)
    end

    it 'should return failed if a macro_list_run or a control_list_run has a failed status' do
      control_list_run.update_attribute(:user_status, 'failed')
      macro_list_run.update_attribute(:user_status, 'warning')
      expect(import_workbench.processed_status).to eq 'failed'
    end

    it 'should return warning if a macro_list_run or a control_list_run has a warning and not failed status' do
      control_list_run.update_attribute(:user_status, 'warning')
      macro_list_run.update_attribute(:user_status, 'successful')
      expect(import_workbench.processed_status).to eq 'warning'
    end

    it 'should return successful if a macro_list_run or a control_list_run have successful statuses' do
      control_list_run.update_attribute(:user_status, 'successful')
      macro_list_run.update_attribute(:user_status, 'successful')
      expect(import_workbench.processed_status).to eq 'successful'
    end

    it 'should return running if a macro_list_run or a control_list_run have not finished' do
      control_list_run.update_attribute(:user_status, 'pending')
      macro_list_run.update_attribute(:user_status, 'pending')
      expect(import_workbench.processed_status).to eq 'running'
    end
  end

  context '#compute_new_status' do
    context 'without compliance_check_sets, macro_list_runs and control_list_runs' do
      let(:context) do
        Chouette.create do
          referential
        end
      end

      it 'should return failed if children_status is failed' do
        allow(import_workbench).to receive(:children_status).and_return 'failed'
        expect(import_workbench.compute_new_status).to eq 'failed'
      end

      it 'should return warning if children_status is warning' do
        allow(import_workbench).to receive(:children_status).and_return 'warning'
        expect(import_workbench.compute_new_status).to eq 'warning'
      end

      it 'should return successful if children_status are successful' do
        allow(import_workbench).to receive(:children_status).and_return 'successful'
        expect(import_workbench.compute_new_status).to eq 'successful'
      end

      it 'should return running if children_status is running' do
        allow(import_workbench).to receive(:children_status).and_return 'running'
        expect(import_workbench.compute_new_status).to eq 'running'
      end
    end

    context 'with compliance_check_sets' do
      let(:context) do
        Chouette.create do
          referential
        end
      end
      let!(:compliance_check_set) do
        create(:compliance_check_set, parent: import_workbench, parent_type: 'Import::Workbench', workbench: workbench,
                                      notified_parent_at: Date.today)
      end

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

    context 'with macro_list_runs or control_list_runs' do
      let(:context) do
        Chouette.create do
          referential
          processing_rule
        end
      end
      let(:netex_import) do
        create(:netex_import, parent: import_workbench, workbench: workbench, status: 'failed',
                              notified_parent_at: Date.today)
      end
      let(:control_list) { Control::List.create name: 'Control List 1', workbench: workbench }
      let(:control_list_run) do
        Control::List::Run.create referential: referential, workbench: workbench, name: 'Control',
                                  original_control_list: control_list, creator: 'Webservice'
      end

      before(:each) do
        netex_import.processings.create(processed: control_list_run, processing_rule: context.processing_rule,
                                        workbench: workbench)
      end

      it 'should return failed if children_status or processed_status is failed' do
        allow(import_workbench).to receive(:processed_status).and_return 'failed'
        allow(import_workbench).to receive(:children_status).and_return 'warning'
        expect(import_workbench.compute_new_status).to eq 'failed'
      end

      it 'should return warning if children_status or processed_status is warning' do
        allow(import_workbench).to receive(:processed_status).and_return 'warning'
        allow(import_workbench).to receive(:children_status).and_return 'successful'
        expect(import_workbench.compute_new_status).to eq 'warning'
      end

      it 'should return successful if children_status and processed_status are successful' do
        allow(import_workbench).to receive(:processed_status).and_return 'successful'
        allow(import_workbench).to receive(:children_status).and_return 'successful'
        expect(import_workbench.compute_new_status).to eq 'successful'
      end

      it 'should return running if children_status or processed_status is running' do
        allow(import_workbench).to receive(:processed_status).and_return 'running'
        allow(import_workbench).to receive(:children_status).and_return 'successful'
        expect(import_workbench.compute_new_status).to eq 'running'
      end
    end
  end

  context '#file_type' do
    let(:context) do
      Chouette.create do
        referential
      end
    end
    let(:filename) { 'google-sample-feed.zip' }
    let(:import) do
      Import::Workbench.new workbench: workbench, name: 'test', creator: 'Albator', file: open_fixture(filename),
                            options: options
    end
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
      before { import.workgroup.import_types = ['Import::Gtfs'] }

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

  describe '#done!' do
    let(:context) do
      Chouette.create do
        referential
      end
    end

    context 'when flag_urgent option is selected' do
      before { import_workbench.flag_urgent = true }
      it 'flag referentials as urgent' do
        expect(import_workbench).to receive(:flag_refentials_as_urgent)
        import_workbench.done! true
      end
    end

    context "when flag_urgent option isn't selected" do
      before { import_workbench.flag_urgent = false }
      it "doesn't flag referentials as urgent" do
        expect(import_workbench).to_not receive(:flag_refentials_as_urgent)
        import_workbench.done! true
      end
    end

    context 'when automatic_merge option is selected' do
      before { import_workbench.automatic_merge = true }
      it 'create automatic merge' do
        expect(import_workbench).to receive(:create_automatic_merge)
        import_workbench.done! true
      end
    end

    context "when automatic_merge option isn't selected" do
      before { import_workbench.automatic_merge = false }
      it "doesn't create automatic merge" do
        expect(import_workbench).to_not receive(:create_automatic_merge)
        import_workbench.done! true
      end
    end

    context 'when archive_on_fail option is selected' do
      before { import_workbench.archive_on_fail = true }
      it 'automaticaly archive referentials' do
        expect(import_workbench).to receive(:archive_referentials)
        import_workbench.done! false
      end
    end

    context "when archive_on_fail option isn't selected" do
      before { import_workbench.archive_on_fail = false }
      it "doesn't automaticaly archive referentials" do
        expect(import_workbench).to_not receive(:archive_referentials)
        import_workbench.done! false
      end
    end
  end

  describe '#flag_refentials_as_urgent' do
    let(:context) do
      Chouette.create do
        referential
      end
    end

    # Time.now.round simplifies Time comparaison in specs
    around { |example| Timecop.freeze(Time.now.round) { example.run } }

    let(:referential) do
      # FIXME: Use Chouette.create to create consistent models
      create(:referential).tap do |referential|
        create(:referential_metadata, referential: referential)
      end
    end

    before { import_workbench.resources.create referential: referential }

    it 'flag referential metadatas as urgent' do
      expect do
        import_workbench.flag_refentials_as_urgent
      end.to change { referential.reload.flagged_urgent_at }.from(nil).to(Time.now)
    end
  end

  describe '#create_automatic_merge' do
    let(:context) do
      Chouette.create do
        referential
      end
    end

    before { import_workbench.resources.create referential: referential }

    it 'create a new Merge' do
      expect { import_workbench.create_automatic_merge }.to change { Merge.count }.by(1)
    end

    describe 'new Merge' do
      subject(:merge) { import_workbench.create_automatic_merge }

      it 'has the same creator than the Import' do
        expect(merge.creator).to eq(import_workbench.creator)
      end
      it 'has the same user than the Import' do
        import_workbench.user = User.new
        expect(merge.user).to eq(import_workbench.user)
      end
      it 'has the same workbench than the Import' do
        expect(merge.workbench).to eq(import_workbench.workbench)
      end
      it 'has the same referentials than the Import' do
        expect(merge.referentials).to eq(import_workbench.referentials)
      end
      it 'has the same notification_target than the Import' do
        expect(merge.notification_target).to eq(import_workbench.notification_target)
      end
    end
  end
end
