class EntranceDecorator < AF83::Decorator
  # define_instance_method :name do
  #   object.name.presence || object.default_name
  # end

  decorates Entrance

  set_scope { [ context[:workbench], :stop_area_referential ] }

  # create_action_link
  create_action_link do |l|
    l.content t('stop_areas.actions.new')
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end
end
