# frozen_string_literal: true

module Policy
  class StopAreaProvider < Base
    authorize_by Strategy::Workbench, only: %i[update destroy]
    authorize_by Strategy::Permission
    authorize_by Strategy::NotUsed, only: %i[destroy]

    protected

    def _create?(resource_class)
      if resource_class == ::Chouette::StopArea
        !resource.disable_stop_area_manual_creation
      else
        [
          ::Chouette::StopArea,
          ::Entrance,
          ::StopAreaRoutingConstraint,
          ::Chouette::ConnectionLink,
          ::StopAreaGroup
        ].include?(resource_class)
      end
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
