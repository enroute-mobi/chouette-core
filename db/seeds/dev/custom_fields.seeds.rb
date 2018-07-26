# coding: utf-8

require_relative '../seed_helpers'

Workgroup.find_each do |workgroup|
  puts workgroup.inspect

  workgroup.custom_fields.seed_by(code: "capacity") do |field|
    field.resource_type = "VehicleJourney"
    field.name = "Bus Capacity"
    field.field_type = "list"
    field.options = { list_values: { "0": "", "1": "48 places", "2": "54 places" }}
  end

  workgroup.custom_fields.seed_by(code: "company_commercial_name") do |field|
    field.resource_type = "Company"
    field.name = "Nom commercial"
    field.field_type = "list"
    field.options = { list_values: { "0": "", "1": "OuiBus", "2": "Alsa" }}
  end

  workgroup.custom_fields.seed_by(code: "company_contact_name") do |field|
    field.resource_type = "Company"
    field.name = "Nom du référent"
    field.field_type = "string"
  end

  workgroup.custom_fields.seed_by(code: "stop_area_test_list") do |field|
    field.resource_type = "StopArea"
    field.name = "Test de Liste"
    field.field_type = "list"
    field.options = { list_values: { "0": "", "1": "Valeur 1", "2": "Valeur 2" }}
  end

  workgroup.custom_fields.seed_by(code: "stop_area_test_string") do |field|
    field.resource_type = "StopArea"
    field.name = "Test de Texte"
    field.field_type = "string"
  end

  workgroup.custom_fields.seed_by(code: "stop_area_test_integer") do |field|
    field.resource_type = "StopArea"
    field.name = "Test de Nombre"
    field.field_type = "integer"
  end

  workgroup.custom_fields.seed_by(code: "stop_area_test_attachment") do |field|
    field.resource_type = "StopArea"
    field.name = "Test de Piece Jointe"
    field.field_type = "attachment"
  end
end
