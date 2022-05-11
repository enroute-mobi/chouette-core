class ProcessingRule < ApplicationModel
	extend Enumerize

	belongs_to :workbench, required: true
	belongs_to :processable, polymorphic: true

	enumerize :processable_type, in: %w(Macro::List Control::List)
	enumerize :operation_step, in: %w(after_import before_merge after_merge after_aggregate)
end
