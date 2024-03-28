# frozen_string_literal: true

module Policy
  class Export < Base
    authorize_by Strategy::Permission

    protected

    def _update?
      true
    end
  end
end
