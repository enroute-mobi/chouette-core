# frozen_string_literal: true

class FootnoteDecorator < Af83::Decorator
  decorates Chouette::Footnote

  set_scope { [context[:workbench], context[:referential], context[:line]].compact }

  create_action_link do |l|
    l.content { I18n.t('footnotes.actions.create') }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:referential]
  end
end
