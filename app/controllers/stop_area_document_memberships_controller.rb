# frozen_string_literal: true

class StopAreaDocumentMembershipsController < DocumentMembershipsController
  defaults resource_class: DocumentMembership,
           collection_name: 'document_memberships',
           instance_name: 'document_membership'

  belongs_to :stop_area_referential, singleton: true
  belongs_to :stop_area

  protected

  def documentable_policy_klass
    StopAreaPolicy
  end

  def redirect_path
    workbench_stop_area_referential_stop_area_document_memberships_path(workbench, documentable)
  end
end
