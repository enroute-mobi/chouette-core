# frozen_string_literal: true

class TagDecorator < Af83::Decorator
  decorates Tag

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end
