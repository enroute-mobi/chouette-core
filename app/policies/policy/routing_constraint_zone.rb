# frozen_string_literal: true

module Policy
  class RoutingConstraintZone < Base
    authorize_by Strategy::Referential
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