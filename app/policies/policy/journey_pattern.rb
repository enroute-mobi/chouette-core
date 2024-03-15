# frozen_string_literal: true

module Policy
  class JourneyPattern < Base
    authorize_by Strategy::Referential
    authorize_by Strategy::Permission, only: %i[update]

    alias unassociate_shape? update?

    def duplicate?
      around_can(:duplicate) do
        ::Policy::Route.new(resource.route, context: context).create?(resource.class)
      end
    end

    protected

    def _update?
      true
    end
  end
end
