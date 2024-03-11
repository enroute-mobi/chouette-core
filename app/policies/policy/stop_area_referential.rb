# frozen_string_literal: true

module Policy
  class StopAreaReferential < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      [
        ::StopAreaProvider,
        ::Chouette::StopArea,
        ::Entrance,
        ::StopAreaRoutingConstraint,
        ::Chouette::ConnectionLink,
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
