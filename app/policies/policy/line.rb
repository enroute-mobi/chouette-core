# frozen_string_literal: true

module Policy
  class Line < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::LineProvider
    authorize_by Strategy::Permission
    authorize_by Strategy::Referential, only: %i[create_in_referential]

    def update_activation_dates?
      around_can(:update_activation_dates) { true }
    end

    protected

    def _create?(resource_class)
      if [
        ::Chouette::RoutingConstraintZone
      ].include?(resource_class)
        create_in_referential?(resource_class)
      else
        false
      end
    end

    def _update?
      true
    end

    def _destroy?
      true
    end

    private

    def create_in_referential?(resource_class)
      around_can(:create_in_referential, resource_class) { true }
    end
  end
end
