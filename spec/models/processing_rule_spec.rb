RSpec.describe ProcessingRule, type: :model do
	it { should belong_to(:workbench).required }
  it { should belong_to(:processable).required }

  it { should validate_presence_of(:processable_id) }
  it { should validate_presence_of(:operation_step) }

	it { is_expected.to enumerize(:processable_type).in('Macro::List', 'Control::List') }
	it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge', 'after_aggregate') }
end
