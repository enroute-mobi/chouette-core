# frozen_string_literal: true

module Search
  class WorkgroupImport < AbstractImport
    class Chart < superclass::Chart
      group_by_attribute 'workbench_id', :string, joins: { workbench: {} }, selects: %w[workbenches.name]
    end
  end
end
