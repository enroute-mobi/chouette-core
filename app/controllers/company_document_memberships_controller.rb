# frozen_string_literal: true

class CompanyDocumentMembershipsController < DocumentMembershipsController
  defaults resource_class: DocumentMembership,
           collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :line_referential, singleton: true
  belongs_to :company

  protected

  def documentable_policy_klass
    CompanyPolicy
  end

  def redirect_path
    workbench_line_referential_company_document_memberships_path(workbench, documentable)
  end
end
