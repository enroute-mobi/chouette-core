# frozen_string_literal: true

class ServiceCount < ActiveRecord::Base
  belongs_to :journey_pattern, class_name: 'Chouette::JourneyPattern'
  belongs_to :route, class_name: 'Chouette::Route'
  belongs_to :line, class_name: 'Chouette::Line'

  scope :for_journey_pattern, ->(journey_pattern) { where(journey_pattern_id: journey_pattern.id) }
  scope :for_line, ->(line) { where(line_id: line.id) }
  scope :for_lines, ->(line_ids) { where(line_id: line_ids) }
  scope :for_route, ->(route) { where(route_id: route.id) }

  scope :after, ->(start_date) { where('date >= ?', start_date) }
  scope :before, ->(end_date) { where('date <= ?', end_date) }

  scope :between, lambda { |start_date, end_date|
    if start_date && end_date
      where "date BETWEEN ? AND ?", start_date, end_date
    elsif start_date
      after start_date
    elsif end_date
      before end_date
    end
  }

  acts_as_copy_target

  class << self
    def compute_for_referential(referential, **options)
      ComputeForReferentialBuilder.new(referential, **options).build
    end

    def holes_for_line(line)
      for_line(line).select(:date).group(:date).order(:date)
    end
  end

  class ComputeForReferentialBuilder
    def initialize(referential, lines: nil)
      @referential = referential
      @lines = lines

      @current_attributes = nil
      @current_days_count = nil
    end
    attr_reader :referential, :lines

    def build # rubocop:disable Metrics/MethodLength
      Chouette::Benchmark.measure 'service_counts', referential: referential.id do
        referential.switch do
          delete_all

          ActiveRecord::Base.cache do
            each_time_tables_and_vehicle_journey_count_by_journey_pattern_id do |row|
              if @current_attributes && @current_attributes['journey_pattern_id'] != row['journey_pattern_id']
                insert_service_counts_from_current
              end

              add_row_to_current(row)
            end

            insert_service_counts_from_current if @current_attributes
          end
        end

        inserter.flush
      end
    end

    private

    def delete_all
      request = referential.service_counts
      request = request.where(line_id: lines) if lines
      request.delete_all
    end

    def inserter
      @inserter ||= ReferentialInserter.new(referential) do |config|
        config.add(IdInserter)
        config.add(CopyInserter)
      end
    end

    def each_time_tables_and_vehicle_journey_count_by_journey_pattern_id(&block)
      cursor = PostgreSQLCursor::Cursor.new(time_tables_and_vehicle_journey_count_by_journey_pattern_id)
      cursor.each_row(&block)
    end

    def insert_service_counts_from_current
      @current_days_count.each_date do |date, count|
        service_count = ::ServiceCount.new(@current_attributes.merge({ 'date' => date, 'count' => count }))
        inserter.service_counts << service_count
      end

      @current_attributes = nil
      @current_days_count = nil
    end

    def add_row_to_current(row)
      row_days_count = row_days_count(row)
      return unless row_days_count

      if @current_attributes.nil?
        @current_attributes = row.slice('journey_pattern_id', 'route_id', 'line_id')
        @current_days_count = row_days_count
      else
        @current_days_count += row_days_count
      end
    end

    def row_days_count(row)
      # TODO: use ActiveRecord::Type.lookup(:integer, array: true) when activerecord-postgis-adapter >= 7.1.0
      # see https://github.com/rgeo/activerecord-postgis-adapter/pull/334
      time_table_ids = PG::TextDecoder::Array.new.decode(row['time_table_ids']).map(&:to_i)

      row_days_bit = Cuckoo::DaysBit.merge(*time_table_days_bits.values_at(*time_table_ids).compact)
      return nil unless row_days_bit

      row_days_bit * row['vehicle_journey_count'].to_i
    end

    def time_table_days_bits # rubocop:disable Metrics/MethodLength
      return @time_table_days_bits if @time_table_days_bits

      time_table_days_bits = {}
      time_tables.includes(:dates, :periods).find_each do |time_table|
        days_bit = time_table.to_days_bit
        if days_bit
          time_table_days_bits[time_table.id] = days_bit
        else
          Rails.logger.warn "Empty/invalid TimeTable: #{time_table.inspect}"
        end
      end
      @time_table_days_bits = time_table_days_bits
    end

    def time_tables
      request = referential.time_tables
      if lines
        request = request.joins(vehicle_journeys: { journey_pattern: :route })
                         .where(routes: { line_id: lines })
      end
      request
    end

    def time_tables_and_vehicle_journey_count_by_journey_pattern_id
      <<-SQL
        SELECT
          journey_pattern_id,
          route_id,
          line_id,
          time_table_ids::integer[],
          COUNT(vehicle_journey_id) AS vehicle_journey_count
        FROM (#{time_tables_by_vehicle_journey_subquery}) t
        GROUP BY journey_pattern_id, route_id, line_id, time_table_ids
        ORDER BY journey_pattern_id ASC
      SQL
    end

    def time_tables_by_vehicle_journey_subquery # rubocop:disable Metrics/MethodLength
      request = referential.vehicle_journeys
                           .joins(:time_tables, journey_pattern: :route) \
                           .select(
                             'vehicle_journeys.id AS "vehicle_journey_id"',
                             'journey_patterns.id AS journey_pattern_id',
                             'routes.id AS route_id',
                             'routes.line_id AS line_id',
                             'array_agg(time_tables.id ORDER BY time_tables.id) AS "time_table_ids"'
                           ) \
                           .group('vehicle_journeys.id', 'journey_patterns.id', 'routes.id', 'routes.line_id')
      request = request.where(routes: { line_id: lines }) if lines
      request.to_sql
    end
  end
end
