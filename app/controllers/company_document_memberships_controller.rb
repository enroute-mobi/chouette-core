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

  def collection_path_method
    :workbench_line_referential_company_document_memberships_path
  end

  def member_path_method
    :workbench_line_referential_company_document_membership_path
  end
end
