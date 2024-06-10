class MergeDecorator < AF83::Decorator
  decorates Merge
  set_scope { context[:workbench] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link(
      primary: :show,
      policy: :rollback
    ) do |l|
      l.content t('merges.actions.rollback')
      l.method  :put
      l.href do
        h.rollback_workbench_merge_path(context[:workbench],object)
      end
      l.data {{ confirm: h.t('merges.actions.rollback_confirm') }}
    end

    instance_decorator.action_link(
      primary: :show,
      if: -> () { object.successful? && object.last_aggregate }
    ) do |l|
      l.content t('merges.actions.see_aggregated_offer')
      l.href { h.workbench_referential_path(context[:workbench], object.last_aggregate.new) }
    end

    instance_decorator.action_link(
      primary: :show,
      if: -> () { object.successful? && object.new.present? }
    ) do |l|
      l.content t('merges.actions.see_associated_offer')
      l.href { h.workbench_referential_path(context[:workbench], object.new) }
    end
  end
end
