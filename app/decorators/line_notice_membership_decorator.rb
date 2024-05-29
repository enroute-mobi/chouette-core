# frozen_string_literal: true

class LineNoticeMembershipDecorator < AF83::Decorator
  decorates Chouette::LineNoticeMembership

  set_scope { [context[:workbench], :line_referential, context[:line]] }

  create_action_link(policy: nil, if: -> { check_policy(:create, Chouette::LineNotice, object: context[:line]) })

  action_link(secondary: true) do |l|
    l.content t('line_notice_memberships.actions.edit')
    l.href { [*scope, :line_notice_memberships, :edit] }
    l.icon 'link'
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link do |l|
      l.content t('actions.show')
      l.href { [context[:workbench], :line_referential, object.line_notice] }
      l.icon 'eye'
    end
    instance_decorator.action_link if: -> { h.policy(object.line_notice).update? } do |l|
      l.content t('line_notices.actions.edit')
      l.href { [:edit, context[:workbench], :line_referential, object.line_notice] }
      l.icon 'pencil-alt'
    end
    instance_decorator.action_link if: -> { h.policy(object.line_notice).destroy? } do |l|
      l.content t('line_notices.actions.destroy')
      l.href { [context[:workbench], :line_referential, object.line_notice] }
      l.method :delete
      l.icon 'trash'
      l.icon_class :danger
      l.confirm t('line_notices.actions.destroy_confirm')
    end

    instance_decorator.destroy_action_link do |l|
      l.icon 'unlink'
    end
  end
end
