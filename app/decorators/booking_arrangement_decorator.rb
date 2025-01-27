# frozen_string_literal: true
class BookingArrangementDecorator < Af83::Decorator
  decorates BookingArrangement

  set_scope { [context[:workbench], :line_referential] }

  create_action_link

  with_instance_decorator(&:crud)

  def policy_parent
    context[:workbench].default_line_provider
  end
end
