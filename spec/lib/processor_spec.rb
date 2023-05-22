# frozen_string_literal: true

RSpec.describe Processor do
  let(:context) do
    Chouette.create do
      workgroup do
        workbench do
          referential
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:workbench) { context.workbench }
  let(:workgroup) { context.workgroup }

  context '#before_operation_step' do
    context 'when the given operation is an Import::Gtfs' do
      it 'should return before_import' do
        import = build :gtfs_import
        processor = Processor.new import
        expect(processor.before_operation_step).to eq('before_import')
      end
    end

    context 'when the given operation is an Import::Netex' do
      it 'should return before_import' do
        import = build :netex_import
        processor = Processor.new import
        expect(processor.before_operation_step).to eq('before_import')
      end
    end

    context 'when the given operation is a Merge' do
      it 'should return before_merge' do
        merge = Merge.new(workbench: workbench, referential_ids: [referential.id])
        processor = Processor.new merge
        expect(processor.before_operation_step).to eq('before_merge')
      end
    end

    context 'when the given operation is an Aggregate' do
      it 'should return before_aggregate' do
        aggregate = Aggregate.new(workgroup: workgroup, referential_ids: [referential.id])
        processor = Processor.new aggregate
        expect(processor.before_operation_step).to eq('before_aggregate')
      end
    end
  end

  context '#after_operation_step' do
    context 'when the given operation is an Import::Gtfs' do
      it 'should return after_import' do
        import = build :gtfs_import
        processor = Processor.new import
        expect(processor.after_operation_step).to eq('after_import')
      end
    end

    context 'when the given operation is an Import::Netex' do
      it 'should return after_import' do
        import = build :netex_import
        processor = Processor.new import
        expect(processor.after_operation_step).to eq('after_import')
      end
    end

    context 'when the given operation is a Merge' do
      it 'should return after_merge' do
        merge = Merge.new(workbench: workbench, referential_ids: [referential.id])
        processor = Processor.new merge
        expect(processor.after_operation_step).to eq('after_merge')
      end
    end

    context 'when the given operation is an Aggregate' do
      it 'should return after_aggregate' do
        aggregate = Aggregate.new(workgroup: workgroup, referential_ids: [referential.id])
        processor = Processor.new aggregate
        expect(processor.after_operation_step).to eq('after_aggregate')
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
      let(:processor) { Processor.new import }

      it 'if workbench has no processing rules' do
        expect(processor.workbench_processing_rules('after_import')).to be_empty
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
      let(:processor) { Processor.new import }

      it 'if workbench has processing rules' do
        expect(processor.workbench_processing_rules('after_import')).to eq([macro_processing_rule,
                                                                            control_processing_rule])
      end
    end
  end

  context '#all_workgroup_processing_rules' do
    context 'when a processing rule exists with operation_step after_import' do
      let(:context) do
        Chouette.create do
          workgroup do
            control_list shared: true
          end
        end
      end

      let(:workgroup) { context.workgroup }
      let(:control_list) { context.control_list }
      let(:import) { create :gtfs_import, workbench: workgroup.workbenches.first }
      let(:processor) { Processor.new import }
      let!(:processing_rule) do
        workgroup.processing_rules.create operation_step: 'after_import', processable: control_list
      end
      subject { processor.all_workgroup_processing_rules('after_import') }

      it { is_expected.to contain_exactly processing_rule }
    end
  end

  context '#workgroup_processing_rules' do
    context 'when a processing rule exist without target workbench' do
      let(:context) do
        Chouette.create do
          workgroup do
            control_list shared: true
          end
        end
      end

      let(:workgroup) { context.workgroup }
      let(:control_list) { context.control_list }
      let(:import) { create :gtfs_import, workbench: workgroup.workbenches.first }
      let(:processor) { Processor.new import }
      let!(:processing_rule) do
        workgroup.processing_rules.create operation_step: 'after_import', processable: control_list
      end
      subject { processor.workgroup_processing_rules('after_import') }

      it { is_expected.to contain_exactly processing_rule }
    end

    context 'when a processing rule exist with target workbench 1 equals to processor workbench' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench do
              control_list shared: true
            end
          end
        end
      end

      let(:workgroup) { context.workgroup }
      let(:control_list) { context.control_list }
      let(:import) { create :gtfs_import, workbench: workgroup.workbenches.first }
      let(:processor) { Processor.new import }
      let!(:processing_rule) do
        workgroup.processing_rules.create operation_step: 'after_import', processable: control_list,
                                          target_workbench_ids: []
      end
      subject { processor.workgroup_processing_rules('after_import') }

      it { is_expected.to contain_exactly processing_rule }
    end

    context 'when a processing rule exist with target workbench 1 not equals to processor workbench' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench :import_workbench do
              control_list shared: true
            end
            workbench :other_workbench
          end
        end
      end

      let(:workgroup) { context.workgroup }
      let(:import_workbench) { context.workbench :import_workbench }
      let(:other_workbench) { context.workbench :other_workbench }
      let(:control_list) { context.control_list }
      let(:import) { create :gtfs_import, workbench: import_workbench }
      let(:processor) { Processor.new import }
      let!(:processing_rule) do
        workgroup.processing_rules.create operation_step: 'after_import', processable: control_list,
                                          target_workbench_ids: [other_workbench]
      end
      subject { processor.workgroup_processing_rules('after_import') }

      it { is_expected.to be_empty }
    end
  end
end
