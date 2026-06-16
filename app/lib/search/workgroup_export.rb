# frozen_string_literal: true

module Search
  class WorkgroupExport < AbstractExport
    class Chart < superclass::Chart
      group_by_attribute 'workbench_id', :string, joins: { workbench: {} }, selects: %w[public.workbenches.name]
    end
  end
end
