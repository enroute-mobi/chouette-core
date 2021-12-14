class MacroListDecorator < AF83::Decorator
  decorates Macro::List

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :macro_options do
    Macro.available.map { |m| { id: m.name, text: m.name } }
  end
end
