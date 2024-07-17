# frozen_string_literal: true

module Policy
  class Source < Base
    authorize_by Strategy::Permission

    def retrieve?
      around_can(:retrieve) { true }
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
