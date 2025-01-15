# frozen_string_literal: true

module Control
  class TransportModeCompatibility < Control::Base
    class Run < Control::Base::Run

      def run
        anomalies.each do |anomaly|
          control_messages.create({
            message_attributes: {
              stop_area_name: anomaly.stop_area_name,
              line_name: anomaly.line_name
            },
            criticity: criticity,
            source_id: anomaly.stop_area_id,
            source_type: 'Chouette::StopArea',
            message_key: :transport_mode_compatibility
          })
        end
      end

      def anomalies
        PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
      end

      class Anomaly
        def initialize(attributes)
          attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
        end
        attr_accessor :stop_area_id, :stop_area_name, :line_name
      end

      def query
        <<~SQL
          SELECT base_query.stop_area_id, base_query.stop_area_name, base_query.line_name
          FROM (#{base_query}) base_query
          WHERE NOT base_query.stop_transport_mode = base_query.line_transport_mode
        SQL
      end

      def base_query
        routes
          .joins(:stop_areas, :line)
          .distinct
          .select(
            'stop_areas.id AS stop_area_id',
            'stop_areas.name AS stop_area_name',
            'stop_areas.transport_mode AS stop_transport_mode',
            'lines.transport_mode AS line_transport_mode',
            'lines.name AS line_name'
          ).to_sql
      end

      def routes
        @routes ||= context.routes
      end
    end
  end
end
