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
        analysis.anomalies.each do |anomaly|
          control_messages.create!({
              message_attributes: { date: anomaly.date },
              criticity: criticity,
              source_id: anomaly.line_id,
              source_type: "Chouette::Line"
            })
        end
      end

      def analysis
        @analysis ||=
          Analysis.new(context, weeks_before: weeks_before, weeks_after: weeks_after, maximum_difference: maximum_difference)
      end

      class Analysis

        def initialize(context, options)
          @context = context
          options.each { |k,v| send "#{k}=", v rescue nil }
        end
        attr_accessor :context, :weeks_before, :weeks_after, :maximum_difference

        def anomalies
          PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
        end

        def query
          <<~SQL
            SELECT
              percentage_difference_table.line_id,
              percentage_difference_table.date,
              percentage_difference_table.sum_count,
              percentage_difference_table.avg_sum,
              percentage_difference_table.percentage_difference
            FROM (
              SELECT
                sum_and_avg_table.line_id,
                sum_and_avg_table.date,
                sum_and_avg_table.sum_count,
                sum_and_avg_table.avg_sum,
                ABS((sum_and_avg_table.sum_count - sum_and_avg_table.avg_sum) / sum_and_avg_table.sum_count) * 100 AS percentage_difference
              FROM (
                SELECT
                  A.line_id, A.date,
                  SUM(A.count) AS sum_count,
                  (
                    SELECT
                      avg_table.avg_sum
                    FROM (
                      SELECT
                        sum_table.line_id,
                        AVG(sum_table.sum_count) AS avg_sum
                      FROM ( #{sum_table_query} ) AS sum_table
                      WHERE (EXTRACT(dow from sum_table.date) = EXTRACT(dow from A.date))
                      GROUP BY sum_table.line_id
                    ) AS avg_table
                    WHERE (avg_table.line_id = A.line_id)
                  ) AS avg_sum
                FROM stat_journey_pattern_courses_by_dates A
                WHERE A.date BETWEEN (A.date - #{7 * weeks_before}) AND (A.date + #{7 * weeks_after})
                GROUP BY A.line_id, A.date
              ) AS sum_and_avg_table
              WHERE sum_and_avg_table.sum_count > 0
            ) AS percentage_difference_table
            WHERE percentage_difference_table.percentage_difference > #{maximum_difference}
          SQL
        end

        def sum_table_query
          context.service_counts
            .group(:line_id, :date)
            .select('SUM(count) AS sum_count', :line_id, :date)
            .where("date BETWEEN (date - #{7 * weeks_before}) AND (date + #{7 * weeks_after})")
            .to_sql
        end

        class Anomaly
          def initialize(attributes)
            attributes.each { |k,v| send "#{k}=", v rescue nil  }
          end
          attr_accessor :line_id, :date
        end
      end

    end
  end
end