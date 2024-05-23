class LineNoticeDecorator < AF83::Decorator
  decorates Chouette::LineNotice

  set_scope { [context[:workbench], :line_referential, context[:line]].compact }

  create_action_link do |l|
    l.content t('line_notices.actions.new')
  end

  action_link(
    if: proc { context[:line].present? && check_policy(:attach, Chouette::LineNotice, object: context[:line]) },
    secondary: true
  ) do |l|
    l.content t('line_notices.actions.attach')
    l.href { [:attach, *scope, :line_notices] }
    l.icon 'link'
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
    instance_decorator.action_link if: Proc.new { context[:line].present? }, secondary: true, policy: :detach do |l|
      l.content t('line_notices.actions.detach')
      l.href { [:detach, *scope, object] }
      l.icon 'chain-broken'
      l.method :post
      l.confirm t('line_notices.confirm.detach')
    end
  end

  def policy_parent
    context[:workbench].default_line_provider
  end
end
