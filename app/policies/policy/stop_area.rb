# frozen_string_literal: true

module Policy
  class StopArea < Base
    prepend ::Policy::Documentable

    authorize_by Strategy::StopAreaProvider
    authorize_by Strategy::Permission

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
