module StopAreaControl
  class InternalBase < InternalControl::Base
    def self.object_path(compliance_check, stop_area)
      workbench_stop_area_referential_stop_area_path(
        compliance_check.referential.workbench,
        stop_area.stop_area_referential,
        stop_area
      )
    end

    def self.collection_type(_)
      :stop_areas
    end
  end
end
