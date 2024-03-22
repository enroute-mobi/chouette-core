# frozen_string_literal: true

module Chouette
  class ReferentialController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ReferentialSupport

    belongs_to :referential

    include WithinWorkgroup

    private

    def current_workgroup
      current_workbench&.workgroup
    end

    def current_workbench
      referential&.workgroup&.workbenches&.find_by(organisation: current_organisation)
    end
  end
end
