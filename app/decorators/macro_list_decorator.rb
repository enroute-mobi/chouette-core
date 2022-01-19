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

  define_instance_method :new_macro do |macro|
    klass = macro.class

    attributes = klass.options.map { |k, _| [k, nil] }.to_h # Ensuring that attributes have all options values defined
    attributes.merge!(**macro.attributes.except('position', 'options'))
    attributes.merge!(**macro.options)

    attributes.merge!(name: macro.type) unless attributes['name'] # Set a default name

    attributes.merge!(class_description: macro.class.model_name.human) # Set a default class description

    attributes.merge!(options: klass.options, errors: macro.errors.messages)

    attributes
  end

  define_instance_method :macro_json do |macro|
    JSON.generate(new_macro(macro))
  end

  define_instance_method :macros_json do
    macros = object.macros.map { |m| new_macro(m) }

    JSON.generate(macros)
  end
end
