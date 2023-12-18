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

  def collection_path_method
    :workbench_stop_area_referential_stop_area_document_memberships_path
  end

  def member_path_method
    :workbench_stop_area_referential_stop_area_document_membership_path
  end
end
