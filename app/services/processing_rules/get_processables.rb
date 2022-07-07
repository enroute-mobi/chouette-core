module ProcessingRules
	class GetProcessables < ApplicationService
		attr_reader :parent, :query, :processable_class
	
		def initialize(params)
			@parent = params[:parent]
			@query = params[:query]&.downcase
			@processable_class = params[:processable_type].constantize
			@collection_name = processable_class.model_name.plural
		end
	
		def call
			case processable_class.to_s
			when 'Control::List'
				result = parent.is_a?(Workgroup) ? workgroup.control_lists : control_lists_for_workbench
			when 'Macro::List'
				result = parent.macro_lists
			else
				raise 'processable_type not defined when trying to fetch processables'
			end

			 result.by_text(query).select("#{collection_name}.id, #{collection_name}.name AS text")
		end

		private

		def collection_name
			processable_class.model_name.plural
		end

		def control_lists_for_workbench
			workgroup.control_lists.where("workbench_id = :workbench_id OR (workbench_id != :workbench_id AND shared IS TRUE)", workbench_id: parent.id)
		end

		def workgroup
			@workgroup ||= parent.is_a?(Workgroup) ? parent : parent.workgroup
		end
	end
end
