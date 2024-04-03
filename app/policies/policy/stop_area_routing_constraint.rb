# frozen_string_literal: true

module Policy
  class StopAreaRoutingConstraint < Base
    authorize_by Strategy::StopAreaProvider
    authorize_by Strategy::Permission

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
