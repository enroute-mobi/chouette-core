module ProcessingRules
	class GetProcessables < ApplicationService
		attr_reader :workbench, :query, :processable_class, :workgroup_rule
	
		def initialize(params)
			@workbench = WorkbenchDecorator.new params.fetch(:workbench)
			@query = params[:query]&.downcase
			@workgroup_rule = params.fetch(:workgroup_rule)
			@processable_class = params.fetch(:processable_type).constantize

			Rails.logger.debug("ProcessingRules::GetProcessables - get #{collection_name} for #{parent.class.name} with id #{parent.id}")
		end
	
		def call
			parent
				.send(collection_name) # macro_lists or control_lists
				.by_text(query)
				.select("#{collection_name}.id, #{collection_name}.name AS text")
		end

		private

		def collection_name
			@collection_name ||= processable_class.model_name.plural
		end

		def parent
			workgroup_rule ? workbench.workgroup : workbench
		end

		class WorkbenchDecorator < SimpleDelegator
			def control_lists
				workgroup.control_lists.where("workbench_id = :workbench_id OR (workbench_id != :workbench_id AND shared IS TRUE)", workbench_id: id)
			end
		end
	end
end
