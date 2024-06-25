# frozen_string_literal: true

module Policy
  class PublicationSetup < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      resource_class == ::Publication
    end

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
