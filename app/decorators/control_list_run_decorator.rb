class ControlListRunDecorator < AF83::Decorator
  decorates Control::List::Run

  set_scope { context[:workbench] }

  create_action_link

	action_link(on: %i[index], secondary: :index) do |l|
    l.content t('control_list_run.actions.show')
    l.href { h.workbench_control_lists_path }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
  end

  define_instance_method :control_list_options do
		control_list ? [{ id: control_list.id, text: control_list.name }] : []
  end

	define_instance_method :duration do
		return '-' unless object.started_at

		end_date = object.ended_at.presence || Time.now

		(end_date - object.started_at).minutes
	end

	define_instance_method(:workbench) { context[:workbench] }

	define_instance_method(:control_list) { context[:control_list] }
end
