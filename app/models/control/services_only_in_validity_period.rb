# frozen_string_literal: true

module Control
  class ServicesOnlyInValidityPeriod < Control::Base
    class Run < Control::Base::Run

      def run
        anomalies.each do |anomaly|
          control_messages.create({
            message_attributes: {
              name: anomaly.name,
              vehicle_journey_sum: anomaly.vehicle_journey_sum
            },
            criticity: criticity,
            source_id: anomaly.line_id,
            source_type: 'Chouette::Line',
            message_key: :services_only_in_validity_period
          })
        end
      end

      def anomalies
        PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
      end

      class Anomaly
        def initialize(attributes)
          attributes.each { |k,v| send "#{k}=", v if respond_to?(k) }
        end
        attr_accessor :line_id, :name, :vehicle_journey_sum
      end

      def query
        service_counts.select(columns).distinct.joins(:line).where(condition).group(:line_id, :name).to_sql
      end

      def columns
        <<~SQL
          lines.name AS name, line_id,
          sum(count) AS vehicle_journey_sum
        SQL
      end

      def condition
        <<~SQL
          ( date < COALESCE(lines.active_from, '-infinity') OR
            date > COALESCE(lines.active_until,'infinity')
          ) AND (lines.deactivated = FALSE)
        SQL
      end

      def service_counts
        @service_counts ||= context.service_counts
      end
    end
  end
end
