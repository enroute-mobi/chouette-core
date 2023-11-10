RSpec.describe Import::Workbench do
  let(:context) do
    Chouette.create do
      workbench :workbench do
        referential :referential
      end
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:referential) { context.referential(:referential) }

  let(:filename) { 'OFFRE_TRANSDEV_2017030112251.zip' }
  subject(:import_workbench) do
    create(:workbench_import, workbench: workbench, referential: referential, file: open_fixture(filename))
  end

  describe '#lanch_worker (after_commit)' do
    it do
      is_expected.to have_attributes(
        status: 'running',
        started_at: be_present
      )
    end

    context 'with a GTFS file' do
      let(:filename) { 'google-sample-feed.zip' }

      it 'creates a Import::Gtfs' do
        expect(import_workbench.children).to match_array(
          [
            have_attributes(
              type: 'Import::Gtfs',
              parent: import_workbench,
              workbench: workbench,
              file: be_present,
              name: import_workbench.name,
              creator: 'Web service'
            )
          ]
        )
        expect(import_workbench.messages).to be_empty
      end
    end

    context 'with a NETEX file' do
      it 'creates a Import::Netex' do
        expect(import_workbench.children).to be_empty
        expect(import_workbench.messages).to be_empty
        expect(Delayed::Job.last).to have_attributes(
          payload_object: have_attributes(
            object: import_workbench,
            method_name: :netex_import,
            args: []
          ),
          queue: 'imports'
        )
      end
    end

    context 'with a Neptune file' do
      let(:filename) { 'fake_neptune.zip' }

      it 'creates a Import::Neptune' do
        expect(import_workbench.children).to match_array(
          [
            have_attributes(
              type: 'Import::Neptune',
              parent: import_workbench,
              workbench: workbench,
              file: be_present,
              name: import_workbench.name,
              creator: 'Web service'
            )
          ]
        )
        expect(import_workbench.messages).to be_empty
      end
    end

    context 'with a malformed file' do
      let(:filename) { 'malformed_import_file.zip' }

      it 'creates an error message' do
        expect(import_workbench.children).to be_empty
        expect(import_workbench.messages).to match_array(
          [
            have_attributes(criticity: 'error', message_key: 'unsupported_file_format')
          ]
        )
      end
    end
  end

  context '#children_status' do
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

  context '#processed_status' do
    let(:context) do
      Chouette.create do
        workbench :workbench do
          referential :referential
          workbench_processing_rule
        end
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
      netex_import.processings.create(processed: control_list_run, processing_rule: context.workbench_processing_rule,
                                      workbench: workbench)
      netex_import.processings.create(processed: macro_list_run, processing_rule: context.workbench_processing_rule,
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
    context 'without macro_list_runs and control_list_runs' do
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

    context 'with macro_list_runs or control_list_runs' do
      let(:context) do
        Chouette.create do
          workbench :workbench do
            referential :referential
            workbench_processing_rule
          end
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
        netex_import.processings.create(processed: control_list_run,
                                        processing_rule: context.workbench_processing_rule,
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
    subject { import_workbench.file_type }

    let(:import_workbench) do
      build(:workbench_import, workbench: workbench, referential: referential, file: open_fixture(filename))
    end

    context 'with a GTFS file' do
      let(:filename) { 'google-sample-feed.zip' }
      it { is_expected.to eq :gtfs }
    end

    context 'with a NETEX file' do
      it { is_expected.to eq :netex }
    end

    context 'with a Neptune file' do
      let(:filename) { 'fake_neptune.zip' }
      it { is_expected.to eq :neptune }
    end

    context 'with a malformed file' do
      let(:filename) { 'malformed_import_file.zip' }
      it { is_expected.to be_nil }
    end

    context 'with import_type restriction' do
      before { import_workbench.workgroup.import_types = ['Import::Gtfs'] }

      context 'with a GTFS file' do
        let(:filename) { 'google-sample-feed.zip' }
        it { is_expected.to eq :gtfs }
      end

      context 'with a NETEX file' do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '#done!' do
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
    # Time.now.round simplifies Time comparaison in specs
    around { |example| Timecop.freeze(Time.now.round) { example.run } }

    before { allow(import_workbench).to receive(:referentials).and_return([referential]) }

    it 'flag referential metadatas as urgent' do
      expect do
        import_workbench.flag_refentials_as_urgent
      end.to change { referential.reload.flagged_urgent_at }.from(nil).to(Time.now)
    end
  end

  describe '#create_automatic_merge' do
    before { allow(import_workbench).to receive(:referentials).and_return([referential]) }

    it 'create a new Merge' do
      expect { import_workbench.create_automatic_merge }.to change { Merge.count }.by(1)
    end

    describe 'new Merge' do
      subject(:merge) { import_workbench.create_automatic_merge }

      it 'has the same creator than the Import' do
        expect(merge.creator).to eq(import_workbench.creator)
      end
      it 'has the same user than the Import' do
        import_workbench.user = User.first
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

  describe '#candidate_line_providers' do
    let(:context) do
      Chouette.create do
        referential :referential
        workbench :workbench do
          line_provider :first, name: 'first'
          line_provider :second, name: 'second'
        end
      end
    end

    subject { import_workbench.candidate_line_providers.map(&:name).join(', ') }

    it 'should include all line providers of workbench with order' do
      is_expected.to eq('default, first, second')
    end
  end

  describe '#candidate_stop_area_providers' do
    let(:context) do
      Chouette.create do
        referential :referential
        workbench :workbench do
          stop_area_provider :first, name: 'first'
          stop_area_provider :second, name: 'second'
        end
      end
    end

    subject { import_workbench.candidate_stop_area_providers.map(&:name).join(', ') }

    it 'should include all stop_area providers of workbench with order' do
      is_expected.to eq('Default, first, second')
    end
  end
end
