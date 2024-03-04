# frozen_string_literal: true

module Policy
  class PublicationApi < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      resource_class == ::PublicationApiKey
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
