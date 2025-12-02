# frozen_string_literal: true

RSpec.shared_examples 'ProcessingRule validations' do
  it { is_expected.to belong_to(:processable).required(false) }

  it { is_expected.to validate_presence_of(:operation_step) }

  describe 'processable' do
    let(:control_list) { Chouette.create { control_list }.control_list }

    context 'without processable' do
      context 'without processable setup' do
        it 'has blank error on processable and processing_setup' do
          subject.valid?
          expect(subject.errors.where(:processable_type).map(&:type)).to include(:blank).and not_include(:present)
          expect(subject.errors.where(:processable_id).map(&:type)).to include(:blank).and not_include(:present)
          expect(subject.errors.where(:processing_setup).map(&:type)).to include(:blank).and not_include(:present)
        end
      end

      context 'with processable setup' do
        before { subject.processing_setup = ProcessingRule::ProcessingSetup.new }

        it 'has no error on processable nor processing_setup' do
          subject.valid?
          expect(subject.errors.where(:processable_type).map(&:type)).to not_include(:blank).and not_include(:present)
          expect(subject.errors.where(:processable_id).map(&:type)).to not_include(:blank).and not_include(:present)
          expect(subject.errors.where(:processing_setup).map(&:type)).to not_include(:blank).and not_include(:present)
        end
      end
    end

    context 'with processable' do
      before { subject.processable = control_list }

      context 'without processable setup' do
        it 'has no error on processable nor processing_setup' do
          subject.valid?
          expect(subject.errors.where(:processable_type).map(&:type)).to not_include(:blank).and not_include(:present)
          expect(subject.errors.where(:processable_id).map(&:type)).to not_include(:blank).and not_include(:present)
          expect(subject.errors.where(:processing_setup).map(&:type)).to not_include(:blank).and not_include(:present)
        end
      end

      context 'with processable setup' do
        before { subject.processing_setup = ProcessingRule::ProcessingSetup.new }

        it 'has present error on processable and processing_setup' do
          subject.valid?
          expect(subject.errors.where(:processable_type).map(&:type)).to not_include(:blank).and include(:present)
          expect(subject.errors.where(:processable_id).map(&:type)).to not_include(:blank).and include(:present)
          expect(subject.errors.where(:processing_setup).map(&:type)).to not_include(:blank).and include(:present)
        end
      end
    end
  end
end

RSpec.describe ProcessingRule::Workbench, type: :model do
  let(:context) do
    Chouette.create do
      workbench do
        control_list
        macro_list
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:control_list) { context.control_list }
  let(:macro_list) { context.macro_list }

  include_examples 'ProcessingRule validations'

  it { is_expected.to belong_to(:workbench).required }

  it { is_expected.to enumerize(:processable_type).in('Macro::List', 'Control::List') }

  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge') }

  it { is_expected.to_not allow_value('after_aggregate').for(:operation_step) }

  context 'using a Control List' do
    before { subject.processable = control_list }

    it { is_expected.to validate_presence_of(:control_list_id) }

    it { is_expected.to validate_inclusion_of(:operation_step).in_array(%w[after_import before_merge after_merge]) }
  end

  context 'using a Macro List' do
    before { subject.processable = macro_list }

    it { is_expected.to validate_presence_of(:macro_list_id) }

    it { is_expected.to validate_inclusion_of(:operation_step).in_array(%w[after_import before_merge]) }
  end

  context 'using a processing setup' do
    before { subject.processing_setup = ProcessingRule::ProcessingSetup.new }

    it { expect(subject.processing_setup).to validate_inclusion_of(:type).in_array(%w[]) }
  end

  context 'when another ProcessingRule exists' do
    let(:context) { Chouette.create { workbench_processing_rule } }
    let(:processing_rule) { context.workbench_processing_rule }

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
  let(:context) do
    Chouette.create do
      workbench :workbench do
        control_list shared: true
      end
    end
  end
  let(:workbench) { context.workbench(:workbench) }
  let(:control_list) { context.control_list }

  include_examples 'ProcessingRule validations'

  it { is_expected.to belong_to(:workgroup).required }

  it { is_expected.to enumerize(:processable_type).in('Control::List') }

  it do
    is_expected.to(
      enumerize(:operation_step).in('before_import', 'after_import', 'before_merge', 'after_merge', 'after_aggregate')
    )
  end

  context 'using a Control List' do
    before { subject.processable = control_list }

    it { is_expected.to validate_presence_of(:control_list_id) }

    it do
      is_expected.to(
        validate_inclusion_of(:operation_step).in_array(%w[after_import before_merge after_merge after_aggregate])
      )
    end
  end

  context 'using a processing setup' do
    before { subject.processing_setup = ProcessingRule::ProcessingSetup.new }

    it do
      expect(subject.processing_setup).to(
        validate_inclusion_of(:type).in_array(%w[ProcessingRule::FlamingoValidationProcessingSetup])
      )
    end

    context 'when FlamingoValidationProcessingSetup' do
      before { subject.processing_setup = ProcessingRule::FlamingoValidationProcessingSetup.new }

      it { is_expected.to validate_inclusion_of(:operation_step).in_array(%w[before_import]) }
    end
  end

  context 'when target_workbench_ids and excluded_workbench_ids are both present' do
    subject { context.workgroup_processing_rule }

    let(:context) do
      Chouette.create do
        workbench

        workgroup_processing_rule
      end
    end

    before do
      subject.target_workbench_ids = [1]
      subject.excluded_workbench_ids = [1]
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
