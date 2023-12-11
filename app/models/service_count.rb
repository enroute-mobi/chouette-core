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
    # rubocop:disable Metrics/MethodLength,Metrics/BlockLength,Metrics/AbcSize
    def compute_for_referential(referential)
      Chouette::Benchmark.measure 'service_counts', referential: referential.id do
        referential_inserter = ReferentialInserter.new(referential) do |config|
          config.add(IdInserter)
          config.add(CopyInserter)
        end

        referential.switch do
          delete_all

          ActiveRecord::Base.cache do
            time_table_days_bits = {}
            referential.time_tables.includes(:dates, :periods).find_each do |time_table|
              days_bit = time_table.to_days_bit
              if days_bit
                time_table_days_bits[time_table.id] = days_bit
              else
                Rails.logger.warn "Empty/invalid TimeTable: #{time_table.inspect}"
              end
            end

            current_attributes = nil
            current_days_count = nil

            request = time_tables_and_vehicle_journey_count_by_journey_pattern_id(referential)
            cursor = PostgreSQLCursor::Cursor.new(request)
            cursor.each_row do |row|
              if current_attributes && current_attributes['journey_pattern_id'] != row['journey_pattern_id']
                insert_service_counts(referential_inserter, current_attributes, current_days_count)
                current_attributes = nil
              end

              # TODO: use ActiveRecord::Type.lookup(:integer, array: true) when activerecord-postgis-adapter >= 7.1.0
              # see https://github.com/rgeo/activerecord-postgis-adapter/pull/334
              time_table_ids = PG::TextDecoder::Array.new.decode(row['time_table_ids']).map(&:to_i)
              row_days_bit = Cuckoo::DaysBit.merge(*time_table_days_bits.values_at(*time_table_ids).compact)
              next unless row_days_bit

              row_days_count = row_days_bit * row['vehicle_journey_count'].to_i
              if current_attributes.nil?
                current_attributes = row.slice('journey_pattern_id', 'route_id', 'line_id')
                current_days_count = row_days_count
              else
                current_days_count += row_days_count
              end
            end

            insert_service_counts(referential_inserter, current_attributes, current_days_count) if current_attributes
          end
        end

        referential_inserter.flush
      end
    end
    # rubocop:enable Metrics/MethodLength,Metrics/BlockLength,Metrics/AbcSize

    private

    def insert_service_counts(referential_inserter, service_count_attributes, days_count)
      days_count.each_date do |date, count|
        service_count = new(service_count_attributes.merge('date' => date, 'count' => count))
        referential_inserter.service_counts << service_count
      end
    end

    def time_tables_and_vehicle_journey_count_by_journey_pattern_id(referential)
      <<-SQL
        SELECT
          journey_pattern_id,
          route_id,
          line_id,
          time_table_ids::integer[],
          COUNT(vehicle_journey_id) AS vehicle_journey_count
        FROM (#{time_tables_by_vehicle_journey_subquery(referential)}) t
        GROUP BY journey_pattern_id, route_id, line_id, time_table_ids
        ORDER BY journey_pattern_id ASC
      SQL
    end

    # rubocop:disable Metrics/MethodLength
    def time_tables_by_vehicle_journey_subquery(referential)
      referential.vehicle_journeys
                 .joins(:time_tables, journey_pattern: :route) \
                 .select(
                   'vehicle_journeys.id AS "vehicle_journey_id"',
                   'journey_patterns.id AS journey_pattern_id',
                   'routes.id AS route_id',
                   'routes.line_id AS line_id',
                   'array_agg(time_tables.id ORDER BY time_tables.id) AS "time_table_ids"'
                 ) \
                 .group('vehicle_journeys.id', 'journey_patterns.id', 'routes.id', 'routes.line_id')
                 .to_sql
    end
    # rubocop:enable Metrics/MethodLength
  end

  def self.holes_for_line(line)
    for_line(line).select(:date).group(:date).order(:date)
    # rubocop:enable Metrics/MethodLength
  end

end
