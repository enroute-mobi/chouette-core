# frozen_string_literal: true

RSpec.shared_examples 'ProcessingRule validations' do
  it { is_expected.to belong_to(:processable).required }

  it { is_expected.to validate_presence_of(:operation_step) }
end

RSpec.describe ProcessingRule::Workbench, type: :model do
  include_examples 'ProcessingRule validations'
  it { is_expected.to belong_to(:workbench).required }

  it { is_expected.to enumerize(:processable_type).in('Macro::List', 'Control::List') }
  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge') }

  it { is_expected.to_not allow_value('after_aggregate').for(:operation_step) }

  context 'using a Control List' do
    before { subject.processable_type = Control::List }
    it { is_expected.to validate_presence_of(:control_list_id) }
  end

  context 'using a Macro List' do
    before { subject.processable_type = Macro::List }
    it { is_expected.to validate_presence_of(:macro_list_id) }
  end

  context 'when another ProcessingRule exists' do
    let(:context) { Chouette.create { workbench_processing_rule } }
    let(:processing_rule) { context.workbench_processing_rule }
    let(:workbench) { context.workbench }

    describe 'a new ProcessingRule in the same Workbench with the same operation step and processable type' do
      subject do
        workbench.processing_rules.build(
          operation_step: processing_rule.operation_step,
          processable: processing_rule.processable
        )
      end

      it { expect(subject).to_not be_valid }
    end
  end

  describe '#no_tag_overlap' do
    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }
    let(:macro_list) { Macro::List.create!(name: 'Macro List', workbench: workbench) }
    let(:tag_1) { Tag.create!(name: 'Tag 1', workbench: workbench) }
    let(:tag_2) { Tag.create!(name: 'Tag 2', workbench: workbench) }
    let(:tag_3) { Tag.create!(name: 'Tag 3', workbench: workbench) }

    context 'when required and excluded tags overlap' do
      subject do
        workbench.processing_rules.build(
          operation_step: 'after_import',
          processable: macro_list,
          required_tag_ids: [tag_1.id, tag_2.id],
          excluded_tag_ids: [tag_1.id]
        )
      end

      it do
        expect(subject).to be_invalid

        I18n.with_locale(:en) do
          expect(subject.errors[:excluded_tag_ids]).to include('Required and excluded tags cannot overlap')
          expect(subject.errors[:required_tag_ids]).to include('Required and excluded tags cannot overlap')
        end
      end
    end

    context 'when required and excluded tags do not overlap' do
      subject do
        workbench.processing_rules.build(
          operation_step: 'after_import',
          processable: macro_list,
          required_tag_ids: [tag_1.id, tag_2.id],
          excluded_tag_ids: [tag_3.id]
        )
      end

      it { expect(subject).to be_valid }
    end
  end
end

RSpec.describe ProcessingRule::Workgroup, type: :model do
  include_examples 'ProcessingRule validations'
  it { is_expected.to enumerize(:processable_type).in('Control::List') }
  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge', 'after_aggregate') }

  it { is_expected.to validate_presence_of(:control_list_id) }

  context 'when target_workbench_ids and excluded_workbench_ids are both present' do
    subject do
      ProcessingRule::Workgroup.new(
        operation_step: 'after_import',
        target_workbench_ids: [1],
        excluded_workbench_ids: [1]
      )
    end

    it { expect(subject).to_not be_valid }
  end

  describe '.accept_workbench' do
    subject { described_class.accept_workbench(workbench) }

    let(:context) do
      Chouette.create do
        workgroup do
          workbench :workbench do
            control_list :control_list, shared: true
          end
          workbench :other_workbench
          workgroup_processing_rule control_list: :control_list, operation_step: 'after_import'
        end
      end
    end

    let(:workgroup_processing_rule) { context.workgroup_processing_rule }
    let(:workbench) { context.workbench(:workbench) }
    let(:other_workbench) { context.workbench(:other_workbench) }

    before do
      workgroup_processing_rule.update(
        target_workbench_ids: target_workbench_ids,
        excluded_workbench_ids: excluded_workbench_ids
      )
    end

    context 'when taget and excluded workbenchs are empty' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end

    context 'when taget contains workbench id and excluded is empty' do
      let(:target_workbench_ids) { [workbench.id] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end

    context 'when taget contains other workbench id and excluded is empty' do
      let(:target_workbench_ids) { [other_workbench.id] }
      let(:excluded_workbench_ids) { [] }

      it { expect(subject).to be_empty }
    end

    context 'when taget is empty and excluded contains workbench id' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [workbench.id] }

      it { expect(subject).to be_empty }
    end

    context 'when taget is empty and excluded contains other workbench id' do
      let(:target_workbench_ids) { [] }
      let(:excluded_workbench_ids) { [other_workbench.id] }

      it { expect(subject).to match_array [workgroup_processing_rule] }
    end
  end
end
