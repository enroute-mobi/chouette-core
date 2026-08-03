class ConnectionLinkDecorator < Af83::Decorator
  define_instance_method :name do
    object.name.presence || object.default_name
  end

  decorates Chouette::ConnectionLink

  set_scope { [ context[:workbench], :stop_area_referential ] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :display_direction do
    I18n.t("connection_links.direction.#{both_ways? ? 'both' : 'one'}")
  end

  def policy_parent
    context[:workbench].default_stop_area_provider
  end
end
