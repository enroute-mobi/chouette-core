class MacroListDecorator < AF83::Decorator
  decorates Macro::List

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link

    instance_decorator.action_link(on: %i[show index], policy: :execute, secondary: :show) do |l|
      l.content 'Execute'
      l.href { h.new_workbench_macro_list_macro_list_run_path(scope, object) }
    end

    instance_decorator.destroy_action_link
  end

  define_instance_method :macro_options do
    Macro.available.map { |m| { id: m.name, text: m.name } }
  end

  define_instance_method :new_macro do |macro|
    klass = macro.class

    attributes = klass.options.map { |k, v| [k, nil] }.to_h # Ensuring that attributes have all options values defined
    attributes.merge!(**macro.attributes.except('position', 'options'))
    attributes.merge!(**macro.options)

    attributes.merge!(name: macro.type) unless attributes['name'] # Set a default name

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
