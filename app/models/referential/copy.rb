# Append Referential data into another Referential
# Used into Aggregate for example
class Referential::Copy
  include Measurable

  attr_accessor :source, :target, :source_priority

  def initialize(options = {})
    options.each { |k, v| send "#{k}=", v }
  end

  def mappings
    @mappings ||= [
      Mapper.new(source, target, :routes),

      Mapper.new(source, target, :stop_points).mapping(:route_id, with: :routes),

      Mapper
        .new(source, target, :journey_patterns)
        .mapping(:route_id, with: :routes)
        .mapping(:departure_stop_point_id, with: :stop_points, as: :departure_stop_point, optional: true)
        .mapping(:arrival_stop_point_id, with: :stop_points, as: :arrival_stop_point, optional: true),

      Mapper
        .new(source, target, :vehicle_journeys)
        .mapping(:route_id, with: :routes)
        .mapping(:journey_pattern_id, with: :journey_patterns),

      Mapper
        .new(source, target, :vehicle_journey_at_stops, legacy_id: false)
        .mapping(:stop_point_id, with: :stop_points)
        .mapping(:vehicle_journey_id, with: :vehicle_journeys),

      Mapper
        .new(source, target, :journey_patterns_stop_points, legacy_id: false)
        .mapping(:journey_pattern_id, with: :journey_patterns)
        .mapping(:stop_point_id, with: :stop_points),

      Mapper.new(source, target, :time_tables),

      Mapper
        .new(source, target, :time_table_periods, legacy_id: false)
        .mapping(:time_table_id, with: :time_tables),

      Mapper
        .new(source, target, :time_table_dates, legacy_id: false)
        .mapping(:time_table_id, with: :time_tables),

      Mapper
        .new(source, target, :time_tables_vehicle_journeys, legacy_id: false)
        .mapping(:time_table_id, with: :time_tables)
        .mapping(:vehicle_journey_id, with: :vehicle_journeys),

      Mapper.new(source, target, :footnotes),

      Mapper
        .new(source, target, :footnotes_vehicle_journeys, legacy_id: false)
        .mapping(:footnote_id, with: :footnotes)
        .mapping(:vehicle_journey_id, with: :vehicle_journeys),

      Mapper
        .new(source, target, :referential_codes, legacy_id: false)
        .mapping(:resource_id, with: :vehicle_journeys)
    ]
  end

  def copy
    measure :copy, source: source.id, target: target.id do
      copy_metadatas

      mappings.each do |mapping|
        measure mapping.table_name do
          mapping.copy_table
        end
      end

      measure :drop_legacy_id_column do
        mappings.each(&:drop_legacy_id_column)
      end
    end
  end

  class Mapper
    def initialize(source_referential, target_referential, table_name, legacy_id: true)
      @table_name = table_name
      @source_referential = source_referential
      @target_referential = target_referential
      @legacy_id = legacy_id
    end

    attr_reader :table_name, :source_referential, :target_referential, :legacy_id

    def source_table
      @source_table ||= source_referential.schema.table(table_name)
    end

    def source_full_name
      source_table.full_name
    end

    def target_schema
      target_referential.schema
    end

    def target_full_name
      @target_full_name ||= target_schema.associated_table(source_table).full_name
    end

    def select_query
      <<-SQL
        SELECT #{select}
        FROM #{source_full_name} source_table
        #{joins.join(' ')}
      SQL
    end

    def drop_legacy_id_column
      return unless legacy_id?

      execute("ALTER TABLE #{target_full_name} DROP COLUMN IF EXISTS legacy_id;")
      execute("DROP INDEX IF EXISTS #{table_name}_legacy_id_unique;")
    end

    def mapping(column_name, with:, as: nil, optional: false)
      target_table_as = "target_#{as || with}"

      replace_columns(target_table_as, column_name)
      append_joins(target_schema.table(with).full_name, target_table_as, column_name, optional: optional)

      self
    end

    def copy_table
      return unless select_query

      drop_legacy_id_column
      add_legacy_id_column

      execute "INSERT INTO #{target_full_name} (#{target_columns.join(',')}) (#{select_query})"

      self
    end

    private

    def replace_columns(target_table_as, column_name)
      @source_columns = source_columns.map do |column|
        column.to_sym == column_name ? "#{target_table_as}.id AS #{column_name}" : column
      end
    end

    def append_joins(target_table, target_table_as, column_name, optional: false)
      join = optional ? "LEFT JOIN" : "JOIN"
      joins << <<-SQL
        #{join} #{target_table} #{target_table_as} ON
          #{target_table_as}.legacy_id = source_table.#{column_name}
      SQL
    end

    def legacy_id?
      legacy_id
    end

    def add_legacy_id_column
      return unless legacy_id?

      execute "ALTER TABLE #{target_full_name} ADD COLUMN IF NOT EXISTS legacy_id bigint;"
      execute "CREATE UNIQUE INDEX IF NOT EXISTS #{table_name}_legacy_id_unique ON #{target_full_name}(legacy_id);"
    end

    def connection
      @connection ||= ActiveRecord::Base.connection
    end

    def execute(query)
      connection.execute query
    end

    def source_columns
      @source_columns ||= legacy_id? ? source_table.columns : source_table.columns - ['id']
    end

    def target_columns
      @target_columns ||=
        if legacy_id?
          source_table.columns.map do |column|
            column == 'id' ? 'legacy_id' : column
          end
        else
          source_table.columns - ['id']
        end
    end

    def select
      source_columns
        .map { |column| column.include?(' ') ? column : "source_table.#{column}" }
        .join(',')
    end

    def joins
      @joins ||= []
    end
  end

  def copy_metadatas
    source.metadatas.find_each do |metadata|
      candidate = target.metadatas.with_lines(metadata.line_ids).find { |m| m.periodes == metadata.periodes }
      candidate ||= target.metadatas.build(line_ids: metadata.line_ids, periodes: metadata.periodes,
                                           referential_source: source, created_at: metadata.created_at, updated_at: metadata.created_at)
      candidate.priority = source_priority if source_priority
      candidate.flagged_urgent_at = metadata.flagged_urgent_at if metadata.urgent?
      candidate.save!
    end
  end
  measure :copy_metadatas
end
