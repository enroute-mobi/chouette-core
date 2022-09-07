# -*- coding: utf-8 -*-
require "csv"

class ComplianceCheckMessageExport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :compliance_check_messages

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def column_names
    ["criticity", "message_key", "resource_objectid", "link", "message"].map {|c| ComplianceCheckMessage.tmf(c)}
  end

  def to_csv(options = {})
    csv_string = CSV.generate(options.slice(:col_sep, :quote_char, :force_quotes)) do |csv|
      csv << column_names
      compliance_check_messages.each do |compliance_check_message|
        csv << [
          compliance_check_message.compliance_check.criticity,
          *compliance_check_message.message_attributes.values_at('test_id', 'source_objectid'),
          options[:server_url] + compliance_check_message.message_attributes['source_object_path'],
          I18n.t("compliance_check_messages.#{compliance_check_message.message_key}", compliance_check_message.message_attributes.deep_symbolize_keys)
          ]
      end
    end
    # We add a BOM to indicate we use UTF-8
    "\uFEFF" + csv_string
  end
end
