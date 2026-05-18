# frozen_string_literal: true

module Cron
  class ComputeWidgetsSetupDataCacheJob < MinutesJob
    include Measurable

    def perform_once
      ::Workgroup.find_each do |w|
        compute_widgets_setup_data_cache_for_workgroup(w)
      end
    end

    private

    def compute_widgets_setup_data_cache_for_workgroup(workgroup)
      measure :compute_widgets_setup_data_cache_for_workgroup, workgroup_id: workgroup.id do
        workgroup.widgets.setup_data_cache_computable.find_each(&:update_setup_data_cache!)
      end
    end
  end
end
