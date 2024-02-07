# frozen_string_literal: true

class LineDocumentMembershipsController < DocumentMembershipsController
  defaults resource_class: DocumentMembership,
           collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :line_referential, singleton: true
  belongs_to :line

  private

  def collection_path_method
    :workbench_line_referential_line_document_memberships_path
  end

  def member_path_method
    :workbench_line_referential_line_document_membership_path
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
