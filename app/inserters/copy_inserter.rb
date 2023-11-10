class CopyInserter < ByClassInserter

  attr_reader :target
  def initialize(target, _options = {})
    @target = target
  end

  def flush
    target.switch do
      super
    end
  end

  class Base

    attr_reader :model_class, :parent_inserter

    def initialize(model_class, parent_inserter)
      @model_class = model_class
      @parent_inserter = parent_inserter
    end

    def csv
      @csv ||=
        begin
          csv = CSV.open(csv_file, "wb")
          csv << csv_headers
        end
    end

    def csv_file
      @csv_file ||= Tempfile.new(['copy','.csv'])
    end

    delegate :connection, :columns, to: :model_class
    delegate :target, to: :parent_inserter

    def csv_headers
      @headers ||= columns.map(&:name)
    end

    def insert(model, options = {})
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
      save_csv
      reset_pk_sequence
    end

    def save_csv
      csv.close

      csv_file.rewind
      Rails.logger.info "Copy #{@model_class} #{csv_file.size} bytes"
      model_class.copy_from csv_file

      csv_file.unlink
    end

    def reset_pk_sequence
      target.switch do
        connection.reset_pk_sequence! model_class.table_name
      end
    end

  end

  class VehicleJourneyAtStop < Base

    # id,vehicle_journey_id,stop_point_id,connecting_service_id,boarding_alighting_possibility,arrival_time,departure_time,for_boarding,for_alighting,departure_day_offset,arrival_day_offset,checksum,checksum_source,stop_area_id
    # 1,1,1,,,12:00:00,12:01:00,normal,normal,0,0,b1c0ac4b48e0db6883d4cf8d89bfc0c9968284314445f95569204626db9c22e8,12:01|12:00|0|0,

    def csv_headers
      %w{id vehicle_journey_id stop_point_id connecting_service_id boarding_alighting_possibility arrival_time departure_time for_boarding for_alighting departure_day_offset arrival_day_offset checksum checksum_source stop_area_id}
    end

    def model_class
      Chouette::VehicleJourneyAtStop
    end

    def csv_values(v)
      "#{v.id},#{v.vehicle_journey_id},#{v.stop_point_id},,,#{type_cast_time(v.arrival_time)},#{type_cast_time(v.departure_time)},#{v.for_boarding},#{v.for_alighting},#{v.departure_day_offset},#{v.arrival_day_offset},#{v.checksum},#{v.checksum_source},#{v.stop_area_id}"
    end

    TIME_FORMAT = "%H:%M:%S"

    def type_cast_time(time)
      if time.is_a?(Time)
        time.strftime(TIME_FORMAT)
      else
        time
      end
    end

    def csv
      @csv ||=
        begin
          csv = RawCSV.open(csv_file, "wb")
          csv << csv_headers.join(',')
        end
    end

  end

  class TimeTableDate < Base

    # id,time_table_id,date,in_out,checksum,checksum_source
    # 2,1,2020-11-02,f,83045a5bde1d9dacf6718eed4e13fc18bb288a50eaca34d2ad28aa36bb477444,2020-11-02|-

    def csv_headers
      %w{id time_table_id date in_out checksum checksum_source}
    end

    def csv_values(d)
      "#{d.id},#{d.time_table_id},#{type_cast_date(d.date)},#{type_boolean(d.in_out)},#{d.checksum},#{d.checksum_source}"
    end

    DATE_FORMAT = "%Y-%m-%d"

    def type_boolean(boolean)
      boolean ? 't' : 'f'
    end

    def type_cast_date(date)
      date.strftime(DATE_FORMAT) if date
    end

    def csv
      @csv ||=
        begin
          csv = RawCSV.open(csv_file, "wb")
          csv << csv_headers.join(',')
        end
    end

  end

  class RawCSV

    def initialize(target)
      @target = target
    end

    def self.open(file_name, options)
      new File.open(file_name, options)
    end

    def <<(row)
      @target.puts row
      self
    end

    def close
      @target.close
    end

  end

end
