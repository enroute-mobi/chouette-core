# frozen_string_literal: true

class DocumentDocumentMembershipDecorator < AF83::Decorator
  decorates Document

  set_scope { [context[:workbench], context[:documentable]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link do |l|
      l.content I18n.t('documents.actions.associate')
      l.method :post
      l.href { h.send(context[:collection_path_method], *scope, document_id: object.id) }
    end
  end

  def pagination_param_name
    context[:pagination_param_name]
  end
end
