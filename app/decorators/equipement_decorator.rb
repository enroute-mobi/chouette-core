# frozen_string_literal: true

class EquipementDecorator < Af83::Decorator
  decorates Equipement

  set_scope { [context[:workbench], :shape_referential] }

  create_action_link

  with_instance_decorator(&:crud)

  def policy_parent
    context[:workbench].default_shape_provider
  end
end
