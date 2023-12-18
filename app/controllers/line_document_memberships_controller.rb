# frozen_string_literal: true

class LineDocumentMembershipsController < DocumentMembershipsController
  defaults resource_class: DocumentMembership,
           collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :line_referential, singleton: true
  belongs_to :line

  protected

  def documentable_policy_klass
    LinePolicy
  end

  def redirect_path
    workbench_line_referential_line_document_memberships_path(workbench, documentable)
  end
end
