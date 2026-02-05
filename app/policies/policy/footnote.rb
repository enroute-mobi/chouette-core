# frozen_string_literal: true

module Policy
  class Footnote < Base
    authorize_by Strategy::Referential
    authorize_by Strategy::Permission, only: %i[update destroy]

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
