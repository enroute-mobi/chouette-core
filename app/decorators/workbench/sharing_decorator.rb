# frozen_string_literal: true

class Workbench
  class SharingDecorator < AF83::Decorator
    decorates Workbench::Sharing

    set_scope { [context[:workgroup], context[:workbench]] }

    create_action_link

    with_instance_decorator do |instance_decorator|
      instance_decorator.destroy_action_link
    end
  end
end
