# frozen_string_literal: true

module Policy
  class JourneyPatternCollection < Base
    class << self
      def permission_namespace
        'journey_patterns'
      end
    end

    authorize_by Strategy::Referential
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
