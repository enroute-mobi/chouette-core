# frozen_string_literal: true

class StopAreaGroupDecorator < Af83::Decorator
  decorates StopAreaGroup

  set_scope { [context[:workbench], :stop_area_referential] }

  create_action_link

  with_instance_decorator(&:crud)

  def policy_parent
    context[:workbench].default_stop_area_provider
  end
end
