# frozen_string_literal: true

module Policy
  class Line < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::LineProvider, only: %i[update destroy update_activation_dates]
    authorize_by Strategy::Permission, only: %i[create update destroy update_activation_dates]

    def update_activation_dates?
      around_can(:update_activation_dates) { true }
    end

    protected

    def _create?(resource_class)
      if resource_class == ::Chouette::LineNotice
        ::Policy::LineProvider.new(resource.line_provider, context: context).create?(::Chouette::LineNotice) && \
          create?(::Chouette::LineNoticeMembership)
      elsif resource_class == ::Chouette::LineNoticeMembership
        apply_strategies(:update)
      else
        super
      end
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
