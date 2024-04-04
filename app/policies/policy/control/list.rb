# frozen_string_literal: true

module Policy
  module Control
    class List < Base
      authorize_by Strategy::Workbench, only: %i[update destroy]
      authorize_by Strategy::Permission, only: %i[update destroy]
      authorize_by Strategy::NotUsed, only: %i[destroy]

      def execute?
        around_can(:execute) do
          ::Policy::Workbench.new(resource.workbench, context: context).create?(::Control::List::Run)
        end
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
end
