class StopAreaProviderDecorator < AF83::Decorator
  decorates StopAreaProvider

  create_action_link policy: nil, if: ->{ h.policy(h.parent).synchronize? } do |l|
    l.content StopAreaProvider.t_action('new')
    l.href { h.new_stop_area_referential_stop_area_provider_path }
  end

  with_instance_decorator do |instance_decorator|
    set_scope { object.stop_area_referential }

    instance_decorator.show_action_link
    instance_decorator.edit_action_link
    instance_decorator.destroy_action_link
  end
end
