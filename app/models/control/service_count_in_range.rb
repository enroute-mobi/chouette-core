module Control
  class ServiceCountInRange < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :minimum_service_counts
        option :maximum_service_counts

        validates :minimum_service_counts, :maximum_service_counts, numericality: { only_integer: true, allow_blank: true }
      end
    end
    include Options

    validate :minimum_or_maximum_service_counts

    private

    def minimum_or_maximum_service_counts
      return if minimum_service_counts.present? || maximum_service_counts.present?

      errors.add(:minimum_service_counts, :invalid)
    end

    class Run < Control::Base::Run
      include Options

      def run
        analysis.anomalies.each do |anomaly|
          control_messages.create({
            message_attributes: {
              date: anomaly.date,
              line: anomaly.line_name
            },
            criticity: criticity,
            source_id: anomaly.line_id,
            source_type: 'Chouette::Line',
            message_key: :service_count_in_range
          })
        end
      end

      def analysis
        @analysis ||= Analysis.new(
          context,
          {
            minimum_service_counts: minimum_service_counts,
            maximum_service_counts: maximum_service_counts
          }
        )
      end

      class Analysis
        def initialize(context, options)
          @context = context
          options.each { |k,v| send "#{k}=", v }
        end
        attr_accessor :context, :minimum_service_counts, :maximum_service_counts

        delegate :service_counts, to: :context

        def anomalies
          PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
        end

        def query
          service_counts
            .joins(:line)
            .group(:line_id, :date, 'lines.name')
            .select('SUM(count) AS sum_count', :line_id, :date, 'lines.name AS line_name')
            .having('SUM(count) < ? OR SUM(count) > ?', minimum, maximum)
            .to_sql
        end

        class Anomaly
          def initialize(attributes)
            attributes.each { |k,v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :line_id, :line_name, :date, :sum_count
        end

        private

        def minimum
          minimum_service_counts || "'-infinity'::int"
        end

        def maximum
          maximum_service_counts || "'infinity'::int"
        end
      end
    end
  end
end
