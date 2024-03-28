# frozen_string_literal: true

module Policy
  class TimeTable < Base
    authorize_by Strategy::Referential
    authorize_by Strategy::Permission, only: %i[update destroy]

    def duplicate?
      around_can(:duplicate) do
        ::Policy::Referential.new(resource.referential, context: context).create?(resource.class)
      end
    end

    alias actualize? update?
    alias month? update?

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
