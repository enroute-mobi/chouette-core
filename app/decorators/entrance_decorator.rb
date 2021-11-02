class EntranceDecorator < AF83::Decorator
  # define_instance_method :name do
  #   object.name.presence || object.default_name
  # end

  decorates Chouette::Entrance

  set_scope { [ context[:workbench], :stop_area_referential ] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
