class WorkgroupDecorator < AF83::Decorator
  decorates Workgroup

  create_action_link do |l|
    l.content t('workgroups.actions.new')
  end

  action_link secondary: :index, policy: :workbench_confirm do |l|
    l.href { h.new_workbench_confirmation_path }
    l.content t('workbench_confirmation.new.title')
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link

    instance_decorator.action_link policy: :add_workbench, secondary: :show do |l|
      l.content t('workgroups.actions.add_workbench')
      l.href { h.new_workgroup_workbench_path(object.id) }
    end

    instance_decorator.action_link policy: :setup_deletion, secondary: :show, if: ->{ object.deleted_at.nil? } do |l|
      l.content t('workgroups.actions.setup_workgroup_deletion')
      l.href { h.setup_deletion_workgroup_path(object.id) }
      l.method :put
      l.data {{ confirm: object.class.t_action(:destroy_confirm) }}
      l.icon :trash
      l.icon_class :danger
    end

    instance_decorator.action_link policy: :remove_deletion, secondary: :show, if: ->{ object.deleted_at.present? } do |l|
      l.content t('workgroups.actions.restore_workgroup')
      l.href { h.remove_deletion_workgroup_path(object.id) }
      l.method :put
    end
  end
end
