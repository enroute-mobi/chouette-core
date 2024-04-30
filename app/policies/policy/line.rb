# frozen_string_literal: true

module Policy
  class Line < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::LineProvider, only: %i[update destroy update_activation_dates]
    authorize_by Strategy::Permission, only: %i[create update destroy update_activation_dates]

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

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
