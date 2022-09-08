# -*- coding: utf-8 -*-
require "csv"
require "zip"

class Import::MessageExport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :import_messages

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def label(name)
    I18n.t "vehicle_journey_exports.label.#{name}"
  end

  def column_names
    ["criticity", "message_key", "message", "filename", "line", "column"].map {|c| Import::Message.tmf(c)}
  end

  def to_csv(options = {})
    csv_string = CSV.generate(options) do |csv|
      csv << column_names
      import_messages.each do |import_message|
        resource_attributes = import_message.resource_attributes&.transform_keys{ |key| key.gsub(/_number$/, '') } || {}
        message_attributes = import_message.message_attributes || {}
        csv << [
          import_message.criticity,
          message_attributes['test_id'],
          I18n.t(
            "import_messages.#{import_message.message_key}",
            message_attributes.deep_symbolize_keys.update(
              default: import_message.message_key
            )
          ),
          *resource_attributes&.values_at("filename", "line", "column")
        ]
      end
    end
    # We add a BOM to indicate we use UTF-8
    "\uFEFF" + csv_string
  end

  def to_zip(temp_file,options = {})
    ::Zip::OutputStream.open(temp_file) { |zos| }
    ::Zip::File.open(temp_file.path, ::Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream(label("vj_filename")+route.id.to_s+".csv") { |f| f.puts to_csv(options) }
      zipfile.get_output_stream(label("tt_filename")+".csv") { |f| f.puts time_tables_to_csv(options) }
      zipfile.get_output_stream(label("ftn_filename")+".csv") { |f| f.puts footnotes_to_csv(options) }
    end
  end

end
