module ProcessingRules
	class GetCollection < ApplicationService
		attr_reader :parent
	
		def initialize parent
			@parent = parent
		end
	
		def call
			parent.is_a?(Workgroup) ? processing_rules_for_workgroup : processing_rules_for_workbench
		end

		private

		def processing_rules_for_workbench
			workgroup.processing_rules
      .then { |collection| owner? ? collection : collection.where('target_workbench_ids::integer[] @> ARRAY[?]', workbench.id) }
      .or(parent.processing_rules)
		end

		def processing_rules_for_workgroup
			workgroup.processing_rules
		end

		def owner?
			parent.is_a?(Workgroup) || workbench.workgroup.owner_id == workbench.organisation_id
		end

		def workbench
			@workbench ||= parent.is_a?(Workbench) ? parent : nil
		end

		def workgroup
			@workgroup ||= parent.is_a?(Workgroup) ? parent : parent.workgroup
		end
	end
end
