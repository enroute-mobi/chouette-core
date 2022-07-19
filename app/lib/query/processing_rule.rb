module Query
  class ProcessingRule < Base
		def workbench_rules
			change_scope { |scope| scope.where(workgroup_rule: false) }
		end

		def workgroup_rules
			change_scope { |scope| scope.where(workgroup_rule: true) }
		end

		def target_workbenches(*workbenches)
			workbench_ids = workbenches.map(&:id).join(', ')

			change_scope do |scope|
				scope.where("ARRAY_LENGTH(target_workbench_ids, 1) = 0 OR ARRAY_LENGTH(target_workbench_ids, 1) IS NULL OR target_workbench_ids::integer[] @> ARRAY[#{workbench_ids}]::integer[]")
			end
		end

		def macros
			change_scope { |scope| scope.where(processable_type: 'Macro::List') }
		end

		def controls
			change_scope { |scope| scope.where(processable_type: 'Control::List') }
		end

		def for_workgroup(workgroup)
			change_scope { |scope| scope.where workbench_id: workgroup.workbench_ids }
    end

    def for_workbench(workbench)
			_for_workgroup = Query::ProcessingRule.new(scope).for_workgroup(workbench.workgroup)

      change_scope do |scope|
				if workbench.owner?
					_for_workgroup.scope 
				else
					_for_workbench = scope.where(workbench_id: workbench.id, workgroup_rule: false)
					_for_workgroup = _for_workgroup.workgroup_rules.target_workbenches(workbench).scope

					_for_workbench.or(_for_workgroup)
				end
      end
    end
  end
end
