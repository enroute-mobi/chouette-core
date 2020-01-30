class CopyInserter

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

  def model_class
    Chouette::VehicleJourney
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
    model_class.copy_from csv_file

    csv_file.unlink
  end

end
