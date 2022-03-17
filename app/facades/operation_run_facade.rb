class OperationRunFacade
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
		[
			TableBuilderHelper::Column.new(
				key: :criticity,
				attribute: -> (m) { criticity_span(m.criticity).html_safe },
				sortable: false
			),
			TableBuilderHelper::Column.new(key: :message, attribute: :full_message, sortable: false),
			TableBuilderHelper::Column.new(
				key: :source,
				attribute: -> (m) { '<span class="fa fa-link"></span>'.html_safe },
				link_to: -> (m) { source_link(m) },
				sortable: false
			),
			{ cls: 'table' }
		]
	end

	def paginate_renderer_for(prefix, object)
		PaginateLinkRenderer.new controller: "#{prefix}_messages", action: 'index', workbench_id: workbench.id, "#{prefix}_list_run_id": resource.id, "#{prefix}_run_id": object.id
	end

	def source_link(message)
		message.source.decorate(context: { workbench: workbench }).action_links.first.href
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
