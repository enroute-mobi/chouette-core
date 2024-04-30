# frozen_string_literal: true

module Policy
  class Route < Base
    authorize_by Strategy::Referential
    authorize_by Strategy::Permission, only: %i[create update destroy]

    def duplicate?
      around_can(:duplicate) do
        ::Policy::Referential.new(resource.referential, context: context).create?(resource.class)
      end
    end
    alias create_opposite? duplicate?

    protected

    def _create?(resource_class)
      [
        ::Chouette::JourneyPattern,
        ::Chouette::VehicleJourney
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
