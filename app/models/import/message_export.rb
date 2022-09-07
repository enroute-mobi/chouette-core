# -*- coding: utf-8 -*-
require "csv"

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

  def column_names
    ["criticity", "message_key", "message", "filename", "line", "column"].map {|c| Import::Message.tmf(c)}
  end

  def to_csv(options = {})
    csv_string = CSV.generate(options) do |csv|
      csv << column_names
      import_messages.each do |import_message|
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
          *import_message.resource_attributes&.values_at("filename", "line_number", "column_number")
        ]
      end
    end
    # We add a BOM to indicate we use UTF-8
    "\uFEFF" + csv_string
  end
end
