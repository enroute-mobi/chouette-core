# frozen_string_literal: true

RSpec.shared_examples 'ProcessingRule validations' do
  it { is_expected.to belong_to(:processing).required }

  it { is_expected.to validate_presence_of(:operation_step) }
end

RSpec.describe ProcessingRule::Workbench, type: :model do
  include_examples 'ProcessingRule validations'
  it { is_expected.to belong_to(:workbench).required }

  it { is_expected.to enumerize(:processing_type).in('Macro::List', 'Control::List') }
  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge') }

  it { is_expected.to_not allow_value('after_aggregate').for(:operation_step) }

  context 'using a Control List' do
    before { subject.processing_type = Control::List }
    it { is_expected.to validate_presence_of(:control_list_id) }
  end

  context 'using a Macro List' do
    before { subject.processing_type = Macro::List }
    it { is_expected.to validate_presence_of(:macro_list_id) }
  end

  context 'when another ProcessingRule exists' do
    let(:context) { Chouette.create { processing_rule } }
    let(:processing_rule) { context.processing_rule }
    let(:workbench) { context.workbench }

    describe 'a new ProcessingRule in the same Workbench with the same operation step and processing type' do
      subject do
        workbench.processing_rules.build(
          operation_step: processing_rule.operation_step,
          processing: processing_rule.processing
        )
      end

      it { expect(subject).to_not be_valid }
    end
  end
end

RSpec.describe ProcessingRule::Workgroup, type: :model do
  include_examples 'ProcessingRule validations'
  it { is_expected.to enumerize(:processing_type).in('Control::List') }
  it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge', 'after_aggregate') }

  it { is_expected.to validate_presence_of(:control_list_id) }
end
