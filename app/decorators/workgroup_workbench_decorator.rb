class WorkgroupWorkbenchDecorator < AF83::Decorator
  decorates Workbench

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    def instance_decorator.policy_class
      WorkgroupWorkbenchPolicy
    end
    instance_decorator.crud
  end
end
