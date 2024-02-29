# frozen_string_literal: true

module Policy
  module Macro
    class List < Base
      authorize_by Strategy::Permission, only: %i[create update destroy]
      authorize_by Strategy::NotUsed, only: %i[destroy]

      def execute?
        around_can(:execute) do
          create?(::Macro::List::Run)
        end
      end

      protected

      def _create?(resource_class)
        [
          ::Macro::List::Run
        ].include?(resource_class)
      end

      def _update?
        true
      end

      def _destroy?
        true
      end
    end
  end
end
