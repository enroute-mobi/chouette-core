# frozen_string_literal: true

module Policy
  module Fare
    class Provider < Base
      authorize_by Strategy::Permission
      authorize_by Strategy::NotUsed, only: %i[destroy]

      protected

      def _update?
        true
      end

      def _destroy?
        true
      end
    end
  end
end
