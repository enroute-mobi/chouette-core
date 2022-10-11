module Macro
  class UpdateStopAreaCompassBearing < Macro::Base

    class Run < Macro::Base::Run
      def run
        stop_areas.find_each do |stop_area|
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

      def stop_areas
        scope.stop_areas.relationship_with_shape.without_compass_bearing
      end

      def average_bearings
        @average_bearings ||= stop_areas.average_bearings
      end
    end
  end
end
