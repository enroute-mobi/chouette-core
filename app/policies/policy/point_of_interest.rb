# frozen_string_literal: true

module Policy
  class PointOfInterest < Base
    authorize_by Strategy::ShapeProvider
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
