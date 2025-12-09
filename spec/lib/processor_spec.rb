# frozen_string_literal: true

RSpec.describe Processor do
  subject(:processor) { described_class.new(operation) }

  let(:operation_workbench) { instance_double(Workbench, 'operation_workbench') }
  let(:operation) { double('operation', workbench: operation_workbench) }

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
            workbench_processing_rule operation_step: 'after_import'
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
            workbench_processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control
            workbench_processing_rule :macro_processing_rule, operation_step: 'after_import', macro_list: :macro
          end
        end
      end

      let(:control_processing_rule) { context.workbench_processing_rule(:control_processing_rule) }
      let(:macro_processing_rule) { context.workbench_processing_rule(:macro_processing_rule) }
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
            control_list :control_list, shared: true
            workgroup_processing_rule operation_step: 'after_import', control_list: :control_list
          end
        end
      end

      let(:workgroup) { context.workgroup }
      let(:control_list) { context.control_list }
      let(:import) { create :gtfs_import, workbench: workgroup.workbenches.first }
      let(:processor) { Processor.new import }
      let(:processing_rule) { context.workgroup_processing_rule }
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

  context '#around' do
    subject { processor.around(&block) }

    let(:block) { proc { @block_called = true } }

    it 'calls #before, the block passed as argument and #after' do
      expect(processor).to receive(:before).and_return(true)
      expect(processor).to receive(:after).and_return(:result)
      expect(subject).to eq(:result)
      expect(@block_called).to be(true)
    end

    it 'calls #before but no the block pass as argument nor #after is #before returns false' do
      allow(processor).to receive(:before).and_return(false)
      expect(processor).not_to receive(:after)
      expect(subject).to be(false)
      expect(@block_called).not_to be(true)
    end

    context 'when block raises an exception' do
      let(:block) { proc { raise 'Oops' } }

      it 'does not calls #after and raises the exception' do
        expect(processor).to receive(:before).and_return(true)
        expect(processor).not_to receive(:after)
        expect { subject }.to raise_error(StandardError, 'Oops')
      end
    end
  end

  context '#before' do
    subject { processor.before }

    let(:processing_rule1) { instance_double(ProcessingRule::Base, 'processing_rule1') }
    let(:processing_rule2) { instance_double(ProcessingRule::Base, 'processing_rule2') }
    let(:processing_rule3) { instance_double(ProcessingRule::Base, 'processing_rule3') }

    before do
      allow(processor).to(
        receive(:before_processing_rules).and_return([processing_rule1, processing_rule2, processing_rule3])
      )
    end

    context 'when #before_referentials is nil' do
      before { allow(processor).to receive(:before_referentials).and_return(nil) }

      context 'when all processing rules perform successfully' do
        it 'executes all processing rules with the correct arguments and returns true' do
          expect(processing_rule1).to(
            receive(:perform).with(operation: operation, operation_workbench: operation_workbench).and_return(true)
          )
          expect(processing_rule2).to(
            receive(:perform).with(operation: operation, operation_workbench: operation_workbench).and_return(true)
          )
          expect(processing_rule3).to(
            receive(:perform).with(operation: operation, operation_workbench: operation_workbench).and_return(true)
          )
          is_expected.to be(true)
        end
      end

      context 'when one processing rule does not perform successfully' do
        it 'executes only some processing rules and returns false' do
          expect(processing_rule1).to receive(:perform).and_return(true)
          expect(processing_rule2).to receive(:perform).and_return(false)
          expect(processing_rule3).not_to receive(:perform)
          is_expected.to be(false)
        end
      end
    end

    context 'when #before_referentials is an empty array' do
      before { allow(processor).to receive(:before_referentials).and_return([]) }

      it 'does not perform any processing rule and returns true' do
        expect(processing_rule1).not_to receive(:perform)
        expect(processing_rule2).not_to receive(:perform)
        expect(processing_rule3).not_to receive(:perform)
        subject
        is_expected.to be(true)
      end
    end

    context 'when #before_referentials is an array of referentials' do
      before { allow(processor).to receive(:before_referentials).and_return([referential1, referential2]) }

      let(:referential1) { instance_double(Referential, 'referential1') }
      let(:referential2) { instance_double(Referential, 'referential2') }

      context 'when all processing rules perform successfully' do
        it 'executes all processing rules with the correct arguments and returns true' do
          expect(processing_rule1).to(
            receive(:perform).with(
              referential: referential1,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule2).to(
            receive(:perform).with(
              referential: referential1,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule3).to(
            receive(:perform).with(
              referential: referential1,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule1).to(
            receive(:perform).with(
              referential: referential2,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule2).to(
            receive(:perform).with(
              referential: referential2,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule3).to(
            receive(:perform).with(
              referential: referential2,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          is_expected.to be(true)
        end
      end

      context 'when one processing rule does not perform successfully' do
        it 'executes only some processing rules and returns false' do
          expect(processing_rule1).to(
            receive(:perform).with(
              referential: referential1,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(true)
          )
          expect(processing_rule2).to(
            receive(:perform).with(
              referential: referential1,
              operation: operation,
              operation_workbench: operation_workbench
            ).and_return(false)
          )
          expect(processing_rule3).not_to receive(:perform)
          expect(processing_rule1).not_to(
            receive(:perform).with(
              referential: referential2,
              operation: operation,
              operation_workbench: operation_workbench
            )
          )
          expect(processing_rule2).not_to(
            receive(:perform).with(
              referential: referential2,
              operation: operation,
              operation_workbench: operation_workbench
            )
          )
          is_expected.to be(false)
        end
      end
    end
  end
end
