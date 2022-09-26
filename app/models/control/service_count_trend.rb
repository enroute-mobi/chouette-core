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
        options = { limit: 5000, page: 1 }

        loop do
          ascs = anomaly_service_counts(options)

          ascs.each do |anomaly_service_count|
            control_messages.create!({
              message_attributes: {
                date: anomaly_service_count['date']
              },
              criticity: criticity,
              source_id: anomaly_service_count['line_id'],
              source_type: "Chouette::Line",
              message_key: :anomaly_service_count
            })
          end

          break if ascs.count < options[:limit]
          options[:page] += 1
        end
      end

      def anomaly_service_counts(options={})
        context.anomaly_service_counts(weeks_before, weeks_after, maximum_difference, options)
      end
    end
  end
end