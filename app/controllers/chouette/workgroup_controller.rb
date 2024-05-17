# frozen_string_literal: true

module Chouette
  class WorkgroupController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include WithinWorkgroup

    belongs_to :workgroup, collection_name: :owned_workgroups

    def policy_context_class
      Policy::Context::Workgroup
    end

    private

    def workgroup
      association_chain
      get_parent_ivar(:workgroup)
    end
    alias current_workgroup workgroup

    def owner_workbench
      @owner_workbench ||= workgroup.owner_workbench
    end
    helper_method :owner_workbench
  end
end
