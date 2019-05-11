class ConnectionLinkDecorator < AF83::Decorator
  decorates Chouette::ConnectionLink

  create_action_link do |l|
    l.content t('connection_links.actions.new')
    l.href { h.new_stop_area_referential_connection_link_path }
  end

  with_instance_decorator do |instance_decorator|
    set_scope { object.stop_area_referential }

    instance_decorator.show_action_link

    instance_decorator.edit_action_link do |l|
      l.content t('connection_links.actions.edit')
    end

    instance_decorator.destroy_action_link do |l|
      l.content { h.destroy_link_content('connection_links.actions.destroy') }
      l.data {{ confirm: h.t('connection_links.actions.destroy_confirm') }}
    end
  end
end
