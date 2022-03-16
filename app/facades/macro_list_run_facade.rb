class MacroListRunFacade < OperationRunFacade
	def paginate_renderer_for(macro_run)
		PaginateLinkRenderer.new controller: 'macro_messages', action: 'index', workbench_id: workbench.id, macro_list_run_id: resource.id, macro_run_id: macro_run.id
	end
end
