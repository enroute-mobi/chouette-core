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
      if: -> () { object.status === 'successful' }
    ) do |l|
      l.content t('merges.actions.see_associated_offer')
      l.href { h.referential_path(object) }
    end
  end
end
