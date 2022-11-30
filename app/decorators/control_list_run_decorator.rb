class ControlListRunDecorator < AF83::Decorator
  decorates Control::List::Run

  set_scope { context[:workbench] }

  action_link(on: %i[index], primary: :index) do |l|
    l.content t('control/list/runs.actions.new')
    l.href { h.new_workbench_control_list_run_path }
  end

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

  define_instance_method :group_referentials do
    [].tap do |groups|
      groups << [
        I18n.translate(:editable_datasets, scope: 'control_list_run.referentials'),
        workbench.referentials.editable.sort_by(&:name).pluck(:name, :id)
      ]

      groups << [
        I18n.translate(:merged_datasets, scope: 'control_list_run.referentials'),
        workbench.output.referentials.sort_by(&:created_at).reverse.pluck(:name, :id)
      ]

      groups << [
        I18n.translate(:aggregated_datasets, scope: 'control_list_run.referentials'),
        workgroup.output.referentials.sort_by(&:created_at).reverse.pluck(:name, :id)
      ]
    end
  end
end
