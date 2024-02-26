# frozen_string_literal: true

module Policy
  class Line < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::LineProvider, only: %i[create update destroy update_activation_dates]
    authorize_by Strategy::Permission, only: %i[create update destroy update_activation_dates]
    authorize_by Strategy::Referential, only: %i[create_in_referential]

    def attach?(resource_class)
      around_can(:attach) do
        return false unless resource_class == ::Chouette::LineNotice

        ::Policy::LineNotice.new(
          resource.line_notices.new(
            line_referential: resource.line_referential,
            line_provider: resource.line_provider
          ),
          context: context
        ).update?
      end
    end

    def update_activation_dates?
      around_can(:update_activation_dates) { true }
    end

    protected

    def _create?(resource_class) # rubocop:disable Metrics/MethodLength
      if [
        ::Chouette::LineNotice
      ].include?(resource_class)
        true
      elsif [
        ::Chouette::Route,
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
