# frozen_string_literal: true

module Search
  class WorkgroupImport < AbstractImport
    AUTHORIZED_GROUP_BY_ATTRIBUTES = (superclass::AUTHORIZED_GROUP_BY_ATTRIBUTES + %w[workbench_id]).freeze

    class Chart < superclass::Chart
      private

      def includes_for_label_of_workbench_id
        { workbench: {} }
      end

      def select_for_label_of_workbench_id
        %w[workbenches.name]
      end

      def label_workbench_id_key(key)
        key[1]
      end
    end
  end
end
