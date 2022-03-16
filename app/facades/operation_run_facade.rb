class OperationRunFacade
	attr_reader :resource, :workbench

	def initialize(resource)
		@resource = resource
		@workbench = resource.workbench
	end

	def criticity_span message
		color_map = {
			info: 'green',
			warning: 'gold',
			error: 'red'
		}

		color = color_map[message.criticity.to_sym]

		%{<span class="fa fa-circle text-enroute-chouette-#{color}"></span>}
	end

	def paginate_renderer_for(_message)
		raise 'NoImplementationError'
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
