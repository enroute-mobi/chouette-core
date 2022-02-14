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
      l.content t('macro_list_run.actions.new')
      l.href { h.new_workbench_macro_list_macro_list_run_path(scope, object) }
    end

    instance_decorator.destroy_action_link
  end

  define_instance_method :macro_options do
    Macro.available.map { |m| { id: m.name, text: m.model_name.human } }
  end

  define_instance_method :macros_json do
    macros = object.macros.map do |m|
      m.attributes
        .slice('id', 'name', 'comments', 'type')
        .merge(
          errors: m.errors.full_messages,
          html: RenderMacroPartial.call(template: h, id: m.id, type: m.type, validate: true),
          **m.options
        )
    end

    JSON.generate(macros)
  end
end
