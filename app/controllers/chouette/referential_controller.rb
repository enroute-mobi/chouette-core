# frozen_string_literal: true

module Chouette
  class ReferentialController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ReferentialSupport
    include WithinWorkgroup

    private

    def current_workgroup
      current_workbrench&.workgroup
    end

    def current_workbrench
      referential&.workbench
    end
  end
end
