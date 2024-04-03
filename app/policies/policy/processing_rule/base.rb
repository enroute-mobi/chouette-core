# frozen_string_literal: true

module Policy
  module ProcessingRule
    class Base < ::Policy::Base
      class << self
        def permission_namespace
          'processing_rules'
        end
      end

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
end
