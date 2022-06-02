class ControlListDecorator < AF83::Decorator
  decorates Control::List

  set_scope { context[:workbench] }

  create_action_link

  action_link(on: %i[index], secondary: :index) do |l|
    l.content t('control_lists.actions.show')
    l.href { h.workbench_control_list_runs_path }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    same_workbench = ->{ object.workbench_id == context[:workbench].id }

    instance_decorator.edit_action_link secondary: :show, if: same_workbench

    instance_decorator.action_link(on: %i[show index], policy: :execute, secondary: :show) do |l|
      l.content t('control_list_run.actions.new')
      l.href { h.new_workbench_control_list_control_list_run_path(scope, object) }
    end

    instance_decorator.destroy_action_link secondary: :show, if: same_workbench
  end
end