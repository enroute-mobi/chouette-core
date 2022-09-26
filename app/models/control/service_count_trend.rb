module Control
  class ServiceCountTrend < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :weeks_before
        option :weeks_after
        option :maximum_difference 

        validates :weeks_before, :weeks_after, :maximum_difference, numericality: { only_integer: true, greater_than: 0, allow_nil: false }
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        anomaly_service_counts.find_each do |anomaly_service_count|
          control_messages.create({
            message_attributes: {
              date: anomaly_service_count.data
            },
            criticity: criticity,
            source_id: anomaly_service_count.line_id,
            message_key: :anomaly_service_count
          })
        end
      end

      def anomaly_service_counts
        @anomaly_service_counts ||= 
          context.anomaly_service_counts(weeks_before, weeks_after, maximum_difference)
      end
    end
  end
end
