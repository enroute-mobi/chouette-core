RSpec.describe Import::Base, type: :model do
  subject(:import) { Import::Base.new }

  it { should belong_to(:referential) }
  it { should belong_to(:workbench) }
  it { should belong_to(:parent) }

  it {
    should enumerize(:status).in('aborted', 'canceled', 'failed', 'new', 'pending', 'running', 'successful', 'warning')
  }

  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:creator) }

  describe '.purge_imports' do
    let(:workbench) { create(:workbench) }
    let(:other_workbench) { create(:workbench) }

    it 'removes files from imports older than 60 days' do
      file_purgeable = Timecop.freeze(60.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      other_file_purgeable = Timecop.freeze(60.days.ago) do
        create(:workbench_import, workbench: other_workbench)
      end

      Import::Workbench.new(workbench: workbench).purge_imports

      expect(file_purgeable.reload.file_url).to be_nil
      expect(other_file_purgeable.reload.file_url).not_to be_nil
    end

    it 'removes imports older than 90 days' do
      old_import = Timecop.freeze(90.days.ago) do
        create(:workbench_import, workbench: workbench)
      end

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.to change {
        old_import.workbench.imports.purgeable.count
      }.from(1).to(0)

      expect { Import::Workbench.new(workbench: workbench).purge_imports }.not_to change {
        old_import.workbench.imports.purgeable.count
      }
    end
  end

  context '#user_file' do
    before do
      subject.name = 'Dummy Import Example'
    end

    it 'uses a parameterized version of the Import name as base name' do
      expect(subject.user_file.basename).to eq('dummy-import-example')
    end

    it 'uses the Import content_type' do
      expect(subject.user_file.content_type).to eq(subject.content_type)
    end

    it 'uses the Import file_extension' do
      expect(subject.user_file.extension).to eq(subject.send(:file_extension))
    end
  end

  describe '#file_extension' do
    subject { import.send(:file_extension) }

    [
      [nil, nil],
      ['dummy', nil],
      ['application/x-zip-compressed', 'zip'],
      ['application/zip', 'zip'],
      ['application/xml', 'xml'],
      ['text/xml', 'xml']
    ].each do |content_type, expected_file_extension|
      context "when content type is #{content_type.inspect}" do
        before { allow(import).to receive(:content_type).and_return(content_type) }
        it { is_expected.to eq(expected_file_extension) }
      end
    end
  end

  context '#workbench_processing_rules' do
    context 'returns no processing rules' do
      let(:context) do
        Chouette.create do
          workbench :without_processing_rules
          workbench do
            processing_rule operation_step: 'after_import'
          end
        end
      end
      let(:import) { create :gtfs_import, workbench: context.workbench(:without_processing_rules) }

      it 'if workbench has no processing rules' do
        expect(import.workbench_processing_rules).to be_empty
      end
    end

    context 'return processing rules' do
      let(:context) do
        Chouette.create do
          workbench do
            control_list :control
            macro_list :macro
            processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control
            processing_rule :macro_processing_rule, operation_step: 'after_import', macro_list: :macro
          end
        end
      end
      let(:control_processing_rule) { context.processing_rule(:control_processing_rule) }
      let(:macro_processing_rule) { context.processing_rule(:macro_processing_rule) }
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'if workbench has processing rules' do
        expect(import.workbench_processing_rules).to eq([macro_processing_rule, control_processing_rule])
      end
    end
  end

  context '#workgroup_processing_rules' do
    context 'returns no processing rules' do
      let(:context) { Chouette.create do
        workgroup :without_processing_rules
        workgroup :with_processing_rules do
          control_list
        end
      end
      }

      let(:workgroup) { context.workgroup(:with_processing_rules) }
      let(:control_list) { context.control_list }
      let(:processing_rule) { workgroup.processing_rules.create operation_step: 'after_import', control_list: control_list }
      let(:workgroup_without_processing_rules) { context.workgroup(:without_processing_rules) }

      it 'if workgroup has no processing rules' do
        expect(workgroup_without_processing_rules.processing_rules).to be_empty
      end
    end

    context 'return processing rules' do
      let(:context) { Chouette.create do
        workgroup do
          control_list
        end
      end
      }
      let(:workgroup) { context.workgroup }
      let(:control_list) { context.control_list }      

      it 'if workgroup has processing rules' do
        processing_rule = workgroup.processing_rules.create operation_step: 'after_import', control_list_id: control_list.id
        expect(workgroup.processing_rules).to eq([processing_rule])
      end

      it 'if workgroup has processing rules affected to a target workbench' do
        processing_rule = workgroup.processing_rules.create operation_step: 'after_import', control_list_id: control_list.id, target_workbenches: [workgroup.workbenches.first.id]
        expect(workgroup.processing_rules).to eq([processing_rule])
      end
    end
  end

  context '#processing_rules' do
    context 'returns no processing rules' do
      let(:context) do
        Chouette.create do
          workbench
        end
      end
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'if workbench and workgroup have no processing rules' do
        expect(context.workbench.processing_rules).to be_empty
      end
    end

    context 'return processing rules' do
      let(:context) do
        Chouette.create do
          workbench do
            control_list :control
            macro_list :macro
            processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control
            processing_rule :macro_processing_rule, operation_step: 'after_import', macro_list: :macro
          end
        end
      end
      let(:control_processing_rule) { context.processing_rule(:control_processing_rule) }
      let(:macro_processing_rule) { context.processing_rule(:macro_processing_rule) }
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'in the right order Workbench Macro::List then Workbench Control::List if workbench has processing rules' do
        allow(import).to receive(:workbench_processing_rules).and_return([macro_processing_rule,
                                                                          control_processing_rule])
        expect(import.processing_rules).to eq([macro_processing_rule, control_processing_rule])
      end
    end
  end
end
