# frozen_string_literal: true

module Policy
  class Calendar < Base
    authorize_by Strategy::Workbench
    authorize_by Strategy::Permission

    def share?
      around_can(:share) { true }
    end

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
