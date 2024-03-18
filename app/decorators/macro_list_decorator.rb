class MacroListDecorator < AF83::Decorator
  decorates Macro::List

  set_scope { context[:workbench] }

  create_action_link

  action_link(on: %i[index], secondary: :index) do |l|
    l.content t('macro_lists.actions.show')
    l.href { h.workbench_macro_list_runs_path }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link

    instance_decorator.action_link(on: %i[show index], policy: :execute, secondary: :show) do |l|
      l.content t('macro_list_run.actions.execute')
      l.href { h.new_workbench_macro_list_macro_list_run_path(scope, object) }
    end

    instance_decorator.destroy_action_link
  end
end
