class CopyInserter

  def insert(model)
    self.for(model.class).insert(model)
  end

  def inserters
    @inserters ||= Hash.new { |h,k| h[k] = Base.new(k) }
  end

  def for(model_class)
    inserters[model_class]
  end

  def flush
    inserters.values.each(&:flush)
  end

  class Base

    attr_reader :model_class

    def initialize(model_class)
      @model_class = model_class
    end

    def csv
      @csv ||=
        begin
          csv = CSV.open(csv_file, "wb")
          csv << headers
        end
    end

    def csv_file
      @csv_file ||= Tempfile.new(['copy','.csv'])
    end

    def columns
      model_class.columns
    end

    def connection
      @connection ||= model_class.connection
    end

    def headers
      @headers ||= columns.map(&:name)
    end

    def insert(model)
      csv << csv_values(model)
    end

    def csv_values(model)
      column_values = []

      attributes = model.attributes
      columns.each do |column|
        attribute_name = column.name
        attribute_value = attributes[attribute_name]

        column_value = connection.type_cast(attribute_value, column)
        column_values << column_value
      end

      column_values
    end

    # For test purpose
    def csv_content
      csv.close
      csv_file.rewind
      csv_file.read
    end

    def flush
      csv.close

      csv_file.rewind
      puts "copy #{csv_file.size} bytes to PG"
      model_class.copy_from csv_file

      csv_file.unlink
    end

  end

end
