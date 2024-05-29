# frozen_string_literal: true

class LineNoticeDecorator < AF83::Decorator
  decorates Chouette::LineNotice

  set_scope { [context[:workbench], :line_referential] }

  create_action_link do |l|
    l.content t('line_notices.actions.new')
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:workbench].default_line_provider
  end
end
