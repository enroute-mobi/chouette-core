class JourneyPatternOfferService
  MIN_HOLE_SIZE = 3

  attr_reader :journey_pattern

  def initialize(journey_pattern, referential: nil, line: nil, route: nil)
    @journey_pattern = journey_pattern
    @referential = referential
    @line = line
    @route = route
  end

  def line
    @line ||= @route&.line || @journey_pattern.line
  end

  def referential
    @referential ||= @route&.referential || @journey_pattern.referential
  end

  def period_start
    @period_start || (compute_period && @period_start)
  end

  def period_end
    @period_end || (compute_period && @period_end)
  end

  def circulation_dates
    out = {}
    ActiveRecord::Base.connection.execute(circulation_dates_query).each do |r|
      out[r['date'].to_date] = r['val'].to_i
    end
    out
  end

  private

  def compute_period
    @period_start = nil
    @period_end = nil
    referential.metadatas.each do |m|
      if m.line_ids.include?(line.id)
        @period_start = [@period_start, m.periodes.map(&:min).min].compact.min
        @period_end = [@period_end, m.periodes.map(&:max).max].compact.max
      end
    end
  end

  def dates_subquery
    <<-SQL
    select CURRENT_DATE + i AS date
    from generate_series(#{(period_start - Time.now.to_date).to_i}, #{(period_end - Time.now.to_date).to_i}) i
    SQL
  end

  def circulation_dates_subquery
    <<-SQL
    SELECT dates.date, vehicle_journeys.id AS vehicle_journeys_id, MAX(vehicle_journeys.journey_pattern_id) as journey_pattern_id
    FROM dates
      LEFT JOIN  \"#{referential.slug}\".time_tables ON 1=1
      LEFT JOIN  \"#{referential.slug}\"."time_tables_vehicle_journeys" ON "time_tables_vehicle_journeys"."time_table_id" = "time_tables"."id"
      INNER JOIN \"#{referential.slug}\"."vehicle_journeys" ON "vehicle_journeys"."id" = "time_tables_vehicle_journeys"."vehicle_journey_id"
      INNER JOIN \"#{referential.slug}\"."journey_patterns" ON "vehicle_journeys"."journey_pattern_id" = "journey_patterns"."id"
      INNER JOIN \"#{referential.slug}\"."routes" ON "journey_patterns"."route_id" = "routes"."id"
      LEFT JOIN  \"#{referential.slug}\"."time_table_dates" AS excluded_dates ON excluded_dates."time_table_id" = "time_tables"."id" AND excluded_dates.date = dates.date AND excluded_dates.in_out = false
      LEFT JOIN  \"#{referential.slug}\"."time_table_dates" AS included_dates ON included_dates."time_table_id" = "time_tables"."id" AND included_dates.date = dates.date AND included_dates.in_out = true
      LEFT JOIN  \"#{referential.slug}\"."time_table_periods" AS periods ON periods."time_table_id" = "time_tables"."id" AND periods.period_start <= dates.date AND periods.period_end >= dates.date
    WHERE
      (included_dates.id IS NOT NULL OR (periods.id IS NOT NULL AND (time_tables.int_day_types & POW(2, ((DATE_PART('dow', dates.date)::int+6)%7)+2)::int) > 0) AND excluded_dates.id IS NULL)
      AND vehicle_journeys.journey_pattern_id = #{@journey_pattern.id}
    GROUP BY dates.date, vehicle_journeys.id
    ORDER BY dates.date ASC
    SQL
  end

  def circulation_dates_query
    <<-SQL
    WITH  dates AS (
      #{dates_subquery}
    ), circulation_dates_subquery AS (
      #{circulation_dates_subquery}
    )
    SELECT date, journey_pattern_id, COUNT(DISTINCT(vehicle_journeys_id)) AS val
    FROM circulation_dates_subquery
    GROUP BY date, journey_pattern_id;
    SQL
  end
end
