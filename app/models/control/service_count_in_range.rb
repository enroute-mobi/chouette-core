# frozen_string_literal: true

module Control
  class ServiceCountInRange < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :minimum_service_counts
        option :maximum_service_counts

        validates :minimum_service_counts, :maximum_service_counts,
                  numericality: { only_integer: true, allow_blank: true }
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
          messages.create(
            date: anomaly.date,
            line: anomaly.line_name
          ) do |message|
            message[:source_id] = anomaly.line_id
            message[:source_type] = 'Chouette::Line'
          end
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
          options.each { |k, v| send "#{k}=", v }
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
            .having(*having)
            .order(:date)
            .to_sql
        end

        class Anomaly
          def initialize(attributes)
            attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
          end
          attr_accessor :line_id, :line_name, :date, :sum_count
        end

        private

        def having
          if minimum_service_counts.present? && maximum_service_counts.present?
            ['SUM(count) < ? OR SUM(count) > ?', minimum_service_counts, maximum_service_counts]
          elsif minimum_service_counts.present?
            ['SUM(count) < ?', minimum_service_counts]
          else # maximum_service_counts.present?
            ['SUM(count) > ?', maximum_service_counts]
          end
        end
      end
    end
  end
end
