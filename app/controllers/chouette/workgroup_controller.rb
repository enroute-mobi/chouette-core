# frozen_string_literal: true

module Chouette
  class WorkgroupController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include WithinWorkgroup

    belongs_to :workgroup

    private

    def workgroup
      association_chain
      get_parent_ivar(:workgroup)
    end
    alias current_workgroup workgroup
  end
end
