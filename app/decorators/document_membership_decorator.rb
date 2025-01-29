# frozen_string_literal: true

class DocumentMembershipDecorator < Af83::Decorator
  decorates DocumentMembership

  set_scope { [context[:workbench], context[:documentable]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link(policy: :destroy) do |l|
      l.content { I18n.t('documents.actions.unassociate') }
      l.method :delete
      l.href { h.send(context[:member_path_method], *scope, object) }
    end
  end

  def pagination_param_name
    context[:pagination_param_name]
  end
end
