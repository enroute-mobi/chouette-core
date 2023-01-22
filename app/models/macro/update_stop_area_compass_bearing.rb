# frozen_string_literal: true

module Macro
  class UpdateStopAreaCompassBearing < Macro::Base
    class Run < Macro::Base::Run
      def run
        stop_areas.find_each do |stop_area|
          compass_bearing = average_bearings[stop_area.id]
          next unless compass_bearing

          stop_area.update compass_bearing: compass_bearing
          create_message(stop_area)
        end
      end

      # Create a message for the given StopArea
      # If the StopArea is invalid, an error message is created.
      def create_message(stop_area)
        attributes = {
          message_attributes: { name: stop_area.name, bearing: stop_area.compass_bearing },
          source: stop_area
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless stop_area.valid?

        macro_messages.create!(attributes)
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
