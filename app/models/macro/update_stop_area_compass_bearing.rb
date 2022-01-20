module Macro
  class UpdateStopAreaCompassBearing < Macro::Base

    class Run < Macro::Base::Run
      def run
        return unless referential

        average_bearings = referential.stop_areas.average_bearings
        referential.stop_areas.with_compass_bearing_empty.find_each do |stop_area|
          stop_area.compass_bearing = average_bearings[stop_area.id]
          if stop_area.compass_bearing_changed?
            if stop_area.save
              # create message here
            end
          end
        end
      end
    end
  end
end
