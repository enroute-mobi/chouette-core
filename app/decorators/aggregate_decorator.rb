class AggregateDecorator < AF83::Decorator
  decorates Aggregate
  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.set_scope { [object.workgroup] }

    instance_decorator.show_action_link do |l|
      l.href { h.workgroup_aggregate_path(object.workgroup, object) }
    end

    instance_decorator.action_link(
      primary: :show,
      policy: :rollback
    ) do |l|
      l.content { I18n.t('aggregates.actions.rollback') }
      l.method  :put
      l.href do
        h.rollback_workgroup_aggregate_path(object.workgroup, object)
      end
      l.icon :undo
      l.data {{ confirm: I18n.t('aggregates.actions.rollback_confirm') }}
    end
  end
end
