# frozen_string_literal: true

module Policy
  class ShapeEditor < Base
    class << self
      def permission_namespace
        'shapes'
      end
    end

    authorize_by Strategy::Referential
    authorize_by Strategy::Permission

    protected

    def _update?
      true
    end
  end
end
