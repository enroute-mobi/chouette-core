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

    def current_workgroup
      workgroup
    rescue ::ActiveRecord::RecordNotFound
      nil
    end

    def default_workbench
      @default_workbench ||= workgroup.default_workbench(current_user)
    end
    helper_method :default_workbench

    def workbench_for_resource(resource)
      if current_user.workbenches.include?(resource.workbench)
        resource.workbench
      else
        default_workbench
      end
    end
  end
end
