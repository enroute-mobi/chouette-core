# frozen_string_literal: true

class ReferentialSchema
  include Measurable

  PUBLIC_SCHEMA = 'public'

  def self.current
    current_name = Apartment::Tenant.current
    new(current_name) unless current_name == PUBLIC_SCHEMA
  end

  def initialize(name)
    @name = name
  end
  attr_reader :name

  def create(skip_reduce_tables: false)
    Apartment::Tenant.create name
    reduce_tables unless skip_reduce_tables
  end

  def tables_query
    "SELECT table_name FROM information_schema.tables WHERE table_schema = '#{name}' ORDER BY table_name"
  end

  def table_names
    connection.select_values tables_query
  end

  def table_names_with_schema
    table_names.map { |table_name| "\"#{name}\".#{table_name}" }
  end

  def tables
    @tables ||= Table.create self, table_names
  end

  def analyse
    # With postgresql 9.6 ANALYZE could be used for only one table
    # With postgresql above 9.6 ANALYZE could be used with table list
    # connection.execute "ANALYZE #{table_names.map { |table_name| "#{name}.#{table_name}" }.join(',')}"
    table_names_with_schema.each do |table_name|
      connection.execute "ANALYZE #{table_name}"
    end
  end

  # Tables used by Apartment excluded models
  def self.apartment_excluded_table_names
    Apartment.excluded_models.map(&:constantize).map(&:table_name).map { |s| s.gsub(/public\./, '') }.uniq
  end

  # Table names unused for others schemas than public
  def self.excluded_table_names
    @excluded_table_names ||= apartment_excluded_table_names
  end

  def excluded_table_names
    self.class.excluded_table_names
  end

  # Tables unused for others schemas than public
  def excluded_tables
    @excluded_tables ||= Table.create self, excluded_table_names
  end

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  delegate :raw_connection, to: :connection

  def table(name)
    name = name.to_sym
    tables.find { |table| table.name == name }
  end

  def associated_table(other)
    table(other.name)
  end

  TABLES_WITH_CONSTRAINTS = %w[
    routes stop_points
    journey_patterns journey_patterns_stop_points
    vehicle_journeys vehicle_journey_at_stops
    time_tables time_tables_vehicle_journeys
  ].freeze

  IGNORED_IN_CLONE = %w[ar_internal_metadata schema_migrations].freeze

  def table_names_ordered_by_constraints
    @table_names_ordered_by_constraints ||=
      TABLES_WITH_CONSTRAINTS + (table_names - TABLES_WITH_CONSTRAINTS)
  end

  def cloned_tables_names
    @cloned_tables_names ||= table_names_ordered_by_constraints - IGNORED_IN_CLONE
  end

  def cloned_tables
    @cloned_tables ||= Table.create(self, cloned_tables_names)
  end

  def clone_to(target)
    cloned_tables.each do |table|
      measure table.name do
        table.clone_to target
      end
    end
  end
  measure :clone_to

  def reduce_tables
    excluded_tables.each(&:drop)
  end

  def ==(other)
    other && name == other.name
  end

  def current_value(sequence)
    full_name = "\"#{name}\".#{sequence}"
    connection.select_value "SELECT last_value from #{full_name}"
  end

  class Table
    include Measurable

    def initialize(schema, name)
      @schema = schema
      @name = name.to_sym
    end

    attr_accessor :name, :schema

    mattr_accessor :columns_cache, default: {}

    delegate :connection, :raw_connection, to: :schema

    def self.create(schema, *names)
      names.flatten.map do |name|
        Table.new schema, name
      end.compact
    end

    def ==(other)
      other && schema == other.schema && name == other.name
    end

    def full_name
      @full_name ||= "\"#{schema.name}\".#{name}"
    end

    def drop
      connection.drop_table(full_name, if_exists: true)
    end

    def reset_pk_sequence
      connection.reset_pk_sequence! full_name
    end

    def count
      connection.select_value "SELECT COUNT(*) from #{full_name}"
    end

    def empty?
      connection.select_value("SELECT count(*) FROM (SELECT 1 FROM #{full_name} LIMIT 1) AS t") == 0
    end

    def columns
      columns_cache[name] ||= connection.select_values("SELECT column_name
                                                        FROM information_schema.columns
                                                        WHERE table_schema = '#{schema.name}'
                                                        AND table_name = '#{name}'")
    end

    def clone_to(target)
      return if empty?

      target_table = target.associated_table(self)
      columns_arg = columns.map { |col| "#{col}" }.join(',')

      connection.execute("INSERT INTO #{target_table.full_name} (#{columns_arg})
                         (SELECT #{columns_arg} FROM #{full_name})")

      target_table.reset_pk_sequence
    end
  end
end
