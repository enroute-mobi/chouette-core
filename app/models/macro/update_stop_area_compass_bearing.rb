# frozen_string_literal: true

module Macro
  class UpdateStopAreaCompassBearing < Macro::Base
    class Run < Macro::Base::Run
      def run
        stop_areas.find_each do |stop_area|
          compass_bearing = average_bearings[stop_area.id]
          next unless compass_bearing

          stop_area.update compass_bearing: compass_bearing

          messages.create(source: stop_area, bearing: compass_bearing) do |message|
            message.error! unless stop_area.valid?
          end
        end
      end

      def stop_areas
        scope.stop_areas.without_compass_bearing
      end

      def average_bearings
        @average_bearings ||= stop_areas.average_bearings
      end
    end
  end
end
