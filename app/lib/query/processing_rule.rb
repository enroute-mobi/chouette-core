# frozen_string_literal: true

module Query
  class ProcessingRule < Base

		def workbench_rules
			change_scope { |scope| scope.where(type: 'ProcessingRule::Workbench') }
		end

		def workgroup_rules
			change_scope { |scope| scope.where(type: 'ProcessingRule::Workgroup') }
		end

		def macros
			change_scope { |scope| scope.where(processable_type: 'Macro::List') }
		end

		def controls
			change_scope { |scope| scope.where(processable_type: 'Control::List') }
		end

		def operation_step(step)
			change_scope { |scope| scope.where(operation_step: step) }
		end

		def workbenches workbench_ids
			change_scope { |scope| scope.where(workbench_id: workbench_ids, type: 'ProcessingRule::Workbench') }
		end 

		def workgroups workgroup_ids
			change_scope { |scope| scope.where(workgroup_id: workgroup_ids, type: 'ProcessingRule::Workgroup') }
    end

  end
end