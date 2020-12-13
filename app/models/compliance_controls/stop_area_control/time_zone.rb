module StopAreaControl
  class TimeZone < InternalControl::Base

    def self.default_code; "3-StopArea-1" end

    def self.object_path _, stop_area
      redirect_stop_area_path stop_area
    end

    def self.collection_type(_)
      :associated_stop_areas
    end

    def self.lines_for(compliance_check, stop_area)
      compliance_check.referential.lines.joins(routes: :stop_points).where('stop_points.stop_area_id = ?', stop_area.id).uniq
    end

    def self.compliance_test compliance_check, stop_area
      stop_area.time_zone.present?
    end
  end
end
