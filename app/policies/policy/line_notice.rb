# frozen_string_literal: true

module Policy
  class LineNotice < Base
    authorize_by Strategy::LineProvider
    authorize_by Strategy::Permission
    authorize_by Strategy::NotUsed, only: %i[destroy]

    alias detach? update?

    protected

    def _update?
      true
    end

    def _destroy?
      true
    end
  end
end
