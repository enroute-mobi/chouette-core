class ReferentialSchema

  def initialize(name)
    @name = name
  end
  attr_reader :name

  def tables_query
    "SELECT table_name FROM information_schema.tables WHERE table_schema = '#{name}' ORDER BY table_name"
  end

  def table_names
    @table_names ||= connection.select_values tables_query
  end

  def tables
    @tables ||= Table.create self, table_names
  end

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  delegate :raw_connection, to: :connection

  def table(name)
    tables.find { |table| table.name == name }
  end

  def associated_table(other)
    table(other.name)
  end

  def clone_to(target)
    tables_ordered_by_constraints.each { |table| table.clone_to target }
  end

  TABLES_WITH_CONSTRAINTS = %w{
    routes stop_points
    journey_patterns journey_patterns_stop_points
    vehicle_journeys vehicle_journey_at_stops
    time_tables time_tables_vehicle_journeys
  }

  def table_names_ordered_by_constraints
    @table_names_ordered_by_constraints ||=
      TABLES_WITH_CONSTRAINTS + (table_names - TABLES_WITH_CONSTRAINTS)
  end

  def tables_ordered_by_constraints
    @table_ordered_by_constraints ||= Table.create(self, table_names_ordered_by_constraints)
  end

  def ==(other)
    other && name == other.name
  end

  class Table

    def initialize(schema, name)
      @schema = schema
      @name = name
    end
    attr_accessor :name, :schema

    delegate :connection, :raw_connection, to: :schema

    def self.create(schema, *names)
      names.flatten.map do |name|
        unless IGNORED.include?(name)
          Table.new schema, name
        end
      end.compact
    end

    def ==(other)
      other && schema == other.schema && name == other.name
    end

    def full_name
      @full_name ||= "#{schema.name}.#{name}"
    end

    IGNORED = %w{ar_internal_metadata schema_migrations}.freeze

    def copy_to(io)
      raw_connection.copy_data "COPY #{full_name} TO STDOUT WITH BINARY" do
        while line = raw_connection.get_copy_data do
          io.write line
        end
      end
    end

    def copy_from(io)
      raw_connection.copy_data "COPY #{full_name} FROM STDIN WITH BINARY" do
        begin
          while line = io.readpartial(10.kilobytes)
            raw_connection.put_copy_data line
          end
        rescue EOFError
        end
      end
    end

    def count
      connection.select_value "SELECT COUNT(*) from #{full_name}"
    end

    def empty?
      count == 0
    end

    def clone_to(target)
      return if empty?

      Tempfile.open(binmode: true) do |temp_file|
        copy_to temp_file

        temp_file.flush
        temp_file.rewind

        associated_table = target.associated_table(self)
        associated_table.copy_from temp_file

        temp_file.unlink
      end
    end

  end


end
