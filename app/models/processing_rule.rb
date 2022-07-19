class ProcessingRule < ApplicationModel
	extend Enumerize

	belongs_to :workbench, required: true
	belongs_to :processable, polymorphic: true, required: true
	has_array_of :target_workbenches, class_name: 'Workbench'

	validates_presence_of :processable_id, :operation_step

	enumerize :processable_type, in: %w(Macro::List Control::List)
	enumerize :operation_step, in: %w(after_import before_merge after_merge after_aggregate), scope: :shallow

	def self.query
		::Query::ProcessingRule.new(ProcessingRule.all)
	end
end
