# frozen_string_literal: true

module Policy
  class VehicleJourneyCollection < Base
    class << self
      def permission_namespace
        'vehicle_journeys'
      end
    end

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
