class OperationRunFacade
	include Rails.application.routes.url_helpers

	attr_reader :resource, :workbench

	def initialize(resource)
		@resource = resource
		@workbench = resource.workbench
	end

	def criticity_span criticity
		color_map = {
			info: 'green',
			warning: 'gold',
			error: 'red'
		}

		color = color_map[criticity.to_sym]

		%{<div class="span fa fa-circle text-enroute-chouette-#{color}"></span>}
	end

	def message_table_params
		criticity = TableBuilderHelper::Column.new(key: :criticity, attribute: -> (m) { criticity_span(m.criticity).html_safe }, sortable: false)		
		columns = [
			TableBuilderHelper::Column.new(key: :message, attribute: :full_message, sortable: false),
			TableBuilderHelper::Column.new(
				key: :source,
				attribute: -> (m) { '<span class="fa fa-link"></span>'.html_safe },
				link_to: -> (m) { source_link(m) },
				sortable: false
			)
		]

		columns.unshift(criticity) if resource.is_a?(Macro::List::Run)
		
		[columns, { cls: 'table' }]
	end

	def source_link(message)
		case message.source_type
			when 'Chouette::Line' then workbench_line_referential_line_path(workbench, message.source_id)
			when 'Chouette::StopArea' then workbench_stop_area_referential_stop_area_path(workbench, message.source_id)
			when 'Chouette::JourneyPattern' then resource.try(:referential_id) ? journey_patterns_referential_path(resource.referential_id, journey_pattern_id: message.source_id) : '#'
			when 'Chouette::Company' then workbench_line_referential_company_path(workbench, message.source_id)
		end
	end

	class	PaginateLinkRenderer < WillPaginate::ActionView::LinkRenderer
		attr_reader :url_params

		def initialize(url_params)
			@url_params = url_params
			super()
		end

		protected

		def url(page)
			@template.url_for(url_params.merge(page: page))
		end
	end
end