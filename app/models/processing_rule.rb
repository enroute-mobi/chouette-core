class ProcessingRule < ApplicationModel
	extend Enumerize

	belongs_to :workbench
	belongs_to :processable, polymorphic: true, required: true
	has_array_of :target_workbenches, class_name: 'Workbench'

	validates_presence_of :processable_id, :operation_step

	enumerize :processable_type, in: %w(Macro::List Control::List)
	enumerize :operation_step, in: %w(after_import before_merge after_merge after_aggregate), scope: :shallow

	scope :workgroup, -> { where(workgroup_rule: true) }
	scope :workbench, -> { where(workgroup_rule: false) }
	scope :for_macros, -> { where(processable_type: 'Macro::List') }
	scope :for_controls, -> { where(processable_type: 'Control::List') }
end
