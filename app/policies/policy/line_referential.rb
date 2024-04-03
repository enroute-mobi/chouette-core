# frozen_string_literal: true

module Policy
  class LineReferential < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      [
        ::LineProvider
      ].include?(resource_class)
    end
  end
end
