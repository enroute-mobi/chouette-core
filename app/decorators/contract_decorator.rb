# frozen_string_literal: true

class ContractDecorator < Af83::Decorator
  decorates Contract

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)
end
