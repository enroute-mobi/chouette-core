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
              self.macro_messages.create(
                criticity: "info",
                message_attributes: { value: "Stop Area #{stop_area.name} has a new compass bearing of #{stop_area.compass_bearing}"},
                source: stop_area
              )
            else
              self.macro_messages.create(
                criticity: "error",
                message_attributes: { value: stop_area.errors.details },
                source: stop_area
              )
            end
          end
        end
      end
    end
  end
end
