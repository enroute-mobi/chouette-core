# frozen_string_literal: true

class Workbench
  class SharingDecorator < AF83::Decorator
    decorates Workbench::Sharing

    set_scope { [context[:workgroup], context[:workbench]] }

    create_action_link

    with_instance_decorator do |instance_decorator|
      instance_decorator.show_action_link
      instance_decorator.destroy_action_link
    end

    define_instance_method :human_status do
      h.t(status, scope: 'workbench/sharings.status')
    end

    define_instance_method :human_recipient_type do
      h.t(recipient_type.underscore, scope: 'activerecord.models', count: 1)
    end
  end
end
