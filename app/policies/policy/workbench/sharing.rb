# frozen_string_literal: true

module Policy
  class Workbench
    class Sharing < Base
      authorize_by Strategy::Permission

      protected

      def _destroy?
        true
      end
    end
  end
end
