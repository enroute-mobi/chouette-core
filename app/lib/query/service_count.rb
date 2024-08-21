# frozen_string_literal: true

module Query
  class ServiceCount < Base
    def line_ids(value)
      where(value.map(&:id), :in, :line_id)
    end

    def company_ids(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:line).where(lines: { company_id: value })
      end
    end

    def network_ids(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:line).where(lines: { network_id: value })
      end
    end

    def transport_modes(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:line).where(lines: { transport_mode: value.to_a })
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where(date: period.infinite_time_range)
      end
    end

    def days_of_week(days_of_week)
      change_scope(if: days_of_week.present? && !days_of_week.all?) do |scope|
        if days_of_week.none?
          scope.none
        else
          scope.where(
            "EXTRACT(ISODOW FROM #{scope.connection.quote_column_name('date')}) IN (?)",
            days_of_week.to_iso_array
          )
        end
      end
    end

    # TODO Could use a nice RecurviseQuery common object
    delegate :table_name, to: ::ServiceCount.table_name
    private :table_name
  end
end
