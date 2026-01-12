# frozen_string_literal: true

module Flamingo
  class ValidationSetupDecorator < Af83::Decorator
    decorates ::Flamingo::ValidationSetup

    set_scope { context[:workgroup] }

    create_action_link

    with_instance_decorator(&:crud)
  end
end
