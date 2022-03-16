class ControlListRunFacade < OperationRunFacade
	def paginate_renderer_for(control_run)
		PaginateLinkRenderer.new controller: 'control_messages', action: 'index', workbench_id: workbench.id, control_list_run_id: resource.id, control_run_id: control_run.id
	end
end
