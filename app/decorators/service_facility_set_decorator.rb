# frozen_string_literal: true

class ServiceFacilitySetDecorator < AF83::Decorator
  decorates ServiceFacilitySet

  set_scope { [context[:workbench], context[:referential]] }

  create_action_link

  with_instance_decorator(&:crud)
end
