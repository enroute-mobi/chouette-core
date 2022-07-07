class ProcessingRule < ApplicationModel
	extend Enumerize

	belongs_to :workgroup, optional: true
	belongs_to :workbench, optional: true
	belongs_to :processable, polymorphic: true, required: true
	has_array_of :target_workbenches, class_name: 'Workbench'

	validates_presence_of :processable_id, :operation_step
	validates :target_workbenches, presence: true, if: -> { workgroup? }
	validates_presence_of :workbench_id, unless: -> { workgroup? }

	enumerize :processable_type, in: %w(Macro::List Control::List)
	enumerize :operation_step, in: %w(after_import before_merge after_merge after_aggregate), scope: :shallow

	scope :for_macros, -> { where(processable_type: 'Macro::List') }
	scope :for_controls, -> { where(processable_type: 'Control::List') }

	def parent
		return workgroup if workgroup_id
		return workbench if workbench_id
	end

	def workgroup?
		parent.is_a?(Workgroup)
	end
end
