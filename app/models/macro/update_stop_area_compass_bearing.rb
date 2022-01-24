module Macro
  class UpdateStopAreaCompassBearing < Macro::Base

    class Run < Macro::Base::Run
      def run
        return unless referential

        average_bearings = referential.stop_areas.average_bearings
        referential.stop_areas.without_compass_bearing.find_each do |stop_area|
          stop_area.compass_bearing = average_bearings[stop_area.id]
          if stop_area.save
            self.macro_messages.create(
              criticity: "info",
              message_attributes: { name: stop_area.name, bearing: stop_area.compass_bearing },
              source: stop_area
            )
          else
            self.macro_messages.create(
              criticity: "error",
              message_key: "invalid",
              source: stop_area
            )
          end
        end
      end
    end
  end
end
