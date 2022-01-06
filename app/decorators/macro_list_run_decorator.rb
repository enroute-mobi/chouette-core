class MacroListRunDecorator < AF83::Decorator
  decorates Macro::List::Run

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
  end

  define_instance_method :macro_list_options do
		macro_list ? [{ id: macro_list.id, text: macro_list.name }] : []
  end

	define_instance_method :duration do
		return '-' unless object.started_at

		end_date = object.ended_at.presence || Time.now

		(end_date - object.started_at).minutes
	end

	private

	define_instance_method(:workbench) { context[:workbench] }

	define_instance_method(:macro_list) { context[:macro_list] }
end
