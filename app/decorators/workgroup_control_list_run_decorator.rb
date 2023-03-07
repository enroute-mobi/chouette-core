class WorkgroupControlListRunDecorator < AF83::Decorator
  decorates Control::List::Run

  delegate :workbench
  delegate :control_list

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    def instance_decorator.policy_class
      WorkgroupControlListRunPolicy
    end
    instance_decorator.show_action_link
  end

  define_instance_method :control_list_options do
    control_list ? [{ id: control_list.id, text: control_list.name }] : []
  end

  define_instance_method :duration do
    return '-' unless object.started_at

    end_date = object.ended_at.presence || Time.now

    (end_date - object.started_at).minutes
  end
end
