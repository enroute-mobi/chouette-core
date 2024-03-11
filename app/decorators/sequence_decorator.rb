# frozen_string_literal: true
class SequenceDecorator < AF83::Decorator
  decorates Sequence

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end
