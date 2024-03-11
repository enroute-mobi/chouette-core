# frozen_string_literal: true

module Policy
  class StopAreaProvider < Base
    authorize_by Strategy::Workbench, only: %i[update destroy]
    authorize_by Strategy::Permission
    authorize_by Strategy::NotUsed, only: %i[destroy]

    protected

    def _create?(resource_class)
      [
        ::Chouette::StopArea,
        ::Entrance,
        ::StopAreaRoutingConstraint,
        ::Chouette::ConnectionLink
      ].include?(resource_class)
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
