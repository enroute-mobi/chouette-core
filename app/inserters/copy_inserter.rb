class CopyInserter

  def insert(model)
    self.for(model.class).insert(model)
  end

  def inserters
    @inserters ||= Hash.new { |h,k| h[k] = self.class.insert_class_for(k).new(k) }
  end

  def self.insert_class_for(model_class)
    "CopyInserter::#{model_class.name.demodulize}".constantize
  rescue NameError
    Base
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

  class VehicleJourneyAtStop < Base

    # id,vehicle_journey_id,stop_point_id,connecting_service_id,boarding_alighting_possibility,arrival_time,departure_time,for_boarding,for_alighting,departure_day_offset,arrival_day_offset,checksum,checksum_source,stop_area_id
    # 1,1,1,,,12:00:00,12:01:00,normal,normal,0,0,b1c0ac4b48e0db6883d4cf8d89bfc0c9968284314445f95569204626db9c22e8,12:01|12:00|0|0,

    def csv_values(v)
      [
        v.id,
        v.vehicle_journey_id,
        v.stop_point_id,
        nil,
        nil,
        type_cast_time(v.arrival_time),
        type_cast_time(v.departure_time),
        v.for_boarding,
        v.for_alighting,
        v.departure_day_offset,
        v.arrival_day_offset,
        v.checksum,
        v.checksum_source,
        v.stop_area_id
      ]
    end

    TIME_FORMAT = "%H:%M:%S"

    def type_cast_time(time)
      time.strftime(TIME_FORMAT)
    end

  end

end
