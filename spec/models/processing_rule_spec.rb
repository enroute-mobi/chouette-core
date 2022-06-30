RSpec.describe ProcessingRule, type: :model do
	it { should belong_to(:workbench).optional }
	it { should belong_to(:workgroup).optional }
  it { should belong_to(:processable) }
	it { is_expected.to enumerize(:processable_type).in('Macro::List', 'Control::List') }
	it { is_expected.to enumerize(:operation_step).in('after_import', 'before_merge', 'after_merge', 'after_aggregate') }
end
