# frozen_string_literal: true

module Policy
  class Dashboard < Base
    authorize_by Strategy::Workbench
    authorize_by Strategy::Permission

    alias edit_layout? update?

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
