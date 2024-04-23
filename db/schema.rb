# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_04_23_123123) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "unaccent"

  create_table "aggregate_resources", force: :cascade do |t|
    t.string "workbench_name"
    t.integer "position"
    t.integer "priority"
    t.integer "duration"
    t.jsonb "metrics"
    t.bigint "aggregate_id"
    t.datetime "referential_created_at", null: false
    t.index ["aggregate_id"], name: "index_aggregate_resources_on_aggregate_id"
  end

  create_table "aggregates", force: :cascade do |t|
    t.bigint "workgroup_id"
    t.string "status"
    t.string "name"
    t.bigint "referential_ids", array: true
    t.bigint "new_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "creator"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "notification_target"
    t.datetime "notified_recipients_at"
    t.bigint "user_id"
    t.index ["workgroup_id"], name: "index_aggregates_on_workgroup_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "token"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "metadata", default: {}
    t.bigint "workbench_id"
  end

  create_table "authentications", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.string "subtype"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "saml_idp_entity_id"
    t.string "saml_idp_sso_service_url"
    t.string "saml_idp_slo_service_url"
    t.text "saml_idp_cert"
    t.string "saml_idp_cert_fingerprint"
    t.string "saml_idp_cert_fingerprint_algorithm"
    t.string "saml_authn_context"
    t.string "saml_email_attribute"
    t.index ["organisation_id", "name"], name: "index_authentications_on_organisation_id_and_name", unique: true
    t.index ["saml_idp_entity_id"], name: "index_authentications_on_saml_idp_entity_id"
    t.index ["type"], name: "index_authentications_on_type"
  end

  create_table "calendars", force: :cascade do |t|
    t.string "name"
    t.daterange "date_ranges", array: true
    t.date "dates", array: true
    t.boolean "shared", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "int_day_types"
    t.date "excluded_dates", array: true
    t.jsonb "metadata", default: {}
    t.bigint "workbench_id", null: false
    t.index ["workbench_id"], name: "index_calendars_on_workbench_id"
  end

  create_table "clean_up_results", force: :cascade do |t|
    t.string "message_key"
    t.hstore "message_attributes"
    t.bigint "clean_up_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["clean_up_id"], name: "index_clean_up_results_on_clean_up_id"
  end

  create_table "clean_ups", force: :cascade do |t|
    t.string "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.bigint "referential_id"
    t.date "begin_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "end_date"
    t.string "date_type"
    t.string "data_cleanups", array: true
    t.index ["referential_id"], name: "index_clean_ups_on_referential_id"
  end

  create_table "code_spaces", force: :cascade do |t|
    t.bigint "workgroup_id", null: false
    t.string "short_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "description"
    t.boolean "allow_multiple_values", default: true, null: false
    t.index ["short_name", "workgroup_id"], name: "index_code_spaces_on_short_name_and_workgroup_id", unique: true
    t.index ["workgroup_id"], name: "index_code_spaces_on_workgroup_id"
  end

  create_table "codes", force: :cascade do |t|
    t.bigint "code_space_id", null: false
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_space_id", "resource_type", "resource_id", "value"], name: "index_codes_on_space_resource_and_value", unique: true
    t.index ["code_space_id", "resource_type", "resource_id"], name: "index_codes_on_space_and_resource"
    t.index ["code_space_id"], name: "index_codes_on_code_space_id"
    t.index ["resource_type", "resource_id"], name: "index_codes_on_resource_type_and_resource_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "short_name"
    t.string "default_contact_organizational_unit"
    t.string "default_contact_operating_department_name"
    t.string "code"
    t.string "default_contact_phone"
    t.string "default_contact_fax"
    t.string "default_contact_email"
    t.string "registration_number"
    t.string "default_contact_url"
    t.string "time_zone"
    t.bigint "line_referential_id"
    t.text "import_xml"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "custom_field_values", default: {}
    t.jsonb "metadata", default: {}
    t.string "default_contact_name"
    t.text "default_contact_more"
    t.string "private_contact_name"
    t.string "private_contact_email"
    t.string "private_contact_phone"
    t.string "private_contact_url"
    t.text "private_contact_more"
    t.string "customer_service_contact_name"
    t.string "customer_service_contact_email"
    t.string "customer_service_contact_phone"
    t.string "customer_service_contact_url"
    t.text "customer_service_contact_more"
    t.string "house_number"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "street"
    t.string "town"
    t.string "postcode"
    t.string "postcode_extension"
    t.string "country_code"
    t.string "default_language"
    t.bigint "line_provider_id"
    t.boolean "is_referent", default: false
    t.bigint "referent_id"
    t.string "fare_url"
    t.index ["custom_field_values"], name: "index_companies_on_custom_field_values", using: :gin
    t.index ["line_provider_id"], name: "index_companies_on_line_provider_id"
    t.index ["line_referential_id", "registration_number"], name: "index_companies_on_referential_id_and_registration_number"
    t.index ["line_referential_id"], name: "index_companies_on_line_referential_id"
    t.index ["objectid"], name: "companies_objectid_key", unique: true
    t.index ["referent_id"], name: "index_companies_on_referent_id"
    t.index ["registration_number"], name: "companies_registration_number_key"
  end

  create_table "connection_links", force: :cascade do |t|
    t.bigint "departure_id"
    t.bigint "arrival_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "comment"
    t.integer "link_distance"
    t.string "link_type"
    t.boolean "mobility_restricted_suitability"
    t.boolean "stairs_availability"
    t.boolean "lift_availability"
    t.integer "int_user_needs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "metadata", default: {}
    t.boolean "both_ways", default: false
    t.bigint "stop_area_referential_id"
    t.integer "default_duration"
    t.integer "frequent_traveller_duration"
    t.integer "occasional_traveller_duration"
    t.integer "mobility_restricted_traveller_duration"
    t.jsonb "custom_field_values", default: {}
    t.bigint "stop_area_provider_id"
    t.index ["objectid"], name: "connection_links_objectid_key", unique: true
    t.index ["stop_area_provider_id"], name: "index_connection_links_on_stop_area_provider_id"
    t.index ["stop_area_referential_id"], name: "index_connection_links_on_stop_area_referential_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.string "name"
    t.bigint "line_ids", array: true
    t.bigint "company_id"
    t.bigint "workbench_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contracts_on_company_id"
    t.index ["workbench_id"], name: "index_contracts_on_workbench_id"
  end

  create_table "control_context_runs", force: :cascade do |t|
    t.bigint "control_list_run_id"
    t.string "name"
    t.string "type", null: false
    t.jsonb "options", default: {}
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_list_run_id"], name: "index_control_context_runs_on_control_list_run_id"
  end

  create_table "control_contexts", force: :cascade do |t|
    t.bigint "control_list_id"
    t.string "name"
    t.string "type", null: false
    t.jsonb "options", default: {}
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_list_id"], name: "index_control_contexts_on_control_list_id"
  end

  create_table "control_list_runs", force: :cascade do |t|
    t.bigint "workbench_id"
    t.string "name", null: false
    t.bigint "original_control_list_id"
    t.bigint "referential_id"
    t.string "status"
    t.string "error_uuid"
    t.string "creator"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_status", null: false
    t.index ["original_control_list_id"], name: "index_control_list_runs_on_original_control_list_id"
    t.index ["referential_id"], name: "index_control_list_runs_on_referential_id"
    t.index ["workbench_id"], name: "index_control_list_runs_on_workbench_id"
  end

  create_table "control_lists", force: :cascade do |t|
    t.bigint "workbench_id"
    t.string "name", null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "shared", default: false
    t.index ["workbench_id"], name: "index_control_lists_on_workbench_id"
  end

  create_table "control_messages", force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.bigint "control_run_id"
    t.string "message_key"
    t.string "criticity", null: false
    t.jsonb "message_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_run_id"], name: "index_control_messages_on_control_run_id"
    t.index ["source_type", "source_id"], name: "index_control_messages_on_source_type_and_source_id"
  end

  create_table "control_runs", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "control_list_run_id"
    t.bigint "control_context_run_id"
    t.integer "position", null: false
    t.text "name"
    t.text "comments"
    t.string "criticity", null: false
    t.string "code"
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_context_run_id"], name: "index_control_runs_on_control_context_run_id"
    t.index ["control_list_run_id", "control_context_run_id", "position"], name: "index_control_runs_position", unique: true
    t.index ["control_list_run_id"], name: "index_control_runs_on_control_list_run_id"
  end

  create_table "controls", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "control_list_id"
    t.bigint "control_context_id"
    t.integer "position", null: false
    t.string "name"
    t.text "comments"
    t.string "criticity", null: false
    t.string "code"
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_context_id"], name: "index_controls_on_control_context_id"
    t.index ["control_list_id", "control_context_id", "position"], name: "index_controls_position", unique: true
    t.index ["control_list_id"], name: "index_controls_on_control_list_id"
  end

  create_table "cross_referential_index_entries", force: :cascade do |t|
    t.string "parent_type"
    t.bigint "parent_id"
    t.string "target_type"
    t.bigint "target_id"
    t.string "relation_name"
    t.string "target_referential_slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["relation_name", "parent_type", "parent_id", "target_referential_slug"], name: "cross_referential_index_entries_parent"
    t.index ["relation_name", "target_type", "target_id", "target_referential_slug"], name: "cross_referential_index_entries_target"
    t.index ["relation_name"], name: "index_cross_referential_index_entries_on_relation_name"
  end

  create_table "custom_field_groups", force: :cascade do |t|
    t.bigint "workgroup_id"
    t.string "name"
    t.integer "position"
    t.string "resource_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workgroup_id", "resource_type", "position"], name: "uniq_workgroup_id_and_resource_type_and_position", unique: true
    t.index ["workgroup_id"], name: "index_custom_field_groups_on_workgroup_id"
  end

  create_table "custom_fields", force: :cascade do |t|
    t.string "code"
    t.string "resource_type"
    t.string "name"
    t.string "field_type"
    t.json "options"
    t.bigint "workgroup_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.bigint "custom_field_group_id"
    t.index ["custom_field_group_id"], name: "index_custom_fields_on_custom_field_group_id"
    t.index ["resource_type"], name: "index_custom_fields_on_resource_type"
    t.index ["workgroup_id", "resource_type", "custom_field_group_id", "position"], name: "uniq_workgroup_id_resource_type_custom_field_group_id_position", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "organisation_id"
    t.string "cron"
    t.index ["organisation_id"], name: "index_delayed_jobs_on_organisation_id"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "delayed_workers", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.datetime "last_heartbeat_at"
    t.string "host_name"
    t.string "label"
  end

  create_table "destination_reports", force: :cascade do |t|
    t.bigint "destination_id"
    t.bigint "publication_id"
    t.string "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "error_message"
    t.text "error_backtrace"
    t.index ["destination_id"], name: "index_destination_reports_on_destination_id"
    t.index ["publication_id"], name: "index_destination_reports_on_publication_id"
  end

  create_table "destinations", force: :cascade do |t|
    t.bigint "publication_setup_id"
    t.string "name"
    t.string "type"
    t.jsonb "options", default: {}
    t.string "secret_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "publication_api_id"
    t.index ["publication_api_id"], name: "index_destinations_on_publication_api_id"
    t.index ["publication_setup_id"], name: "index_destinations_on_publication_setup_id"
  end

  create_table "document_memberships", force: :cascade do |t|
    t.bigint "documentable_id", null: false
    t.string "documentable_type", null: false
    t.bigint "document_id"
    t.index ["document_id"], name: "index_document_memberships_on_document_id"
    t.index ["documentable_type", "documentable_id", "document_id"], name: "index_document_memberships_on_documentable_and_document_id", unique: true
  end

  create_table "document_providers", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "workbench_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name", null: false
    t.index ["workbench_id"], name: "index_document_providers_on_workbench_id"
  end

  create_table "document_types", force: :cascade do |t|
    t.bigint "workgroup_id"
    t.string "name"
    t.string "short_name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workgroup_id"], name: "index_document_types_on_workgroup_id"
  end

  create_table "documents", force: :cascade do |t|
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "name", null: false
    t.text "description"
    t.daterange "validity_period"
    t.string "file", null: false
    t.bigint "document_type_id"
    t.bigint "document_provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_provider_id"], name: "index_documents_on_document_provider_id"
    t.index ["document_type_id"], name: "index_documents_on_document_type_id"
  end

  create_table "entrances", force: :cascade do |t|
    t.string "objectid", null: false
    t.string "name"
    t.string "short_name"
    t.bigint "stop_area_id"
    t.bigint "stop_area_provider_id"
    t.bigint "stop_area_referential_id"
    t.boolean "entry_flag", default: false
    t.boolean "exit_flag", default: false
    t.string "entrance_type"
    t.string "description"
    t.geography "position", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "address_line_1"
    t.string "zip_code"
    t.string "city_name"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "postal_region"
    t.index ["objectid"], name: "index_entrances_on_objectid", unique: true
    t.index ["stop_area_id"], name: "index_entrances_on_stop_area_id"
    t.index ["stop_area_provider_id"], name: "index_entrances_on_stop_area_provider_id"
    t.index ["stop_area_referential_id"], name: "index_entrances_on_stop_area_referential_id"
  end

  create_table "export_messages", force: :cascade do |t|
    t.string "criticity"
    t.string "message_key"
    t.hstore "message_attributes"
    t.bigint "export_id"
    t.bigint "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore "resource_attributes"
    t.index ["export_id"], name: "index_export_messages_on_export_id"
    t.index ["resource_id"], name: "index_export_messages_on_resource_id"
  end

  create_table "export_resources", force: :cascade do |t|
    t.bigint "export_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "resource_type"
    t.string "reference"
    t.string "name"
    t.hstore "metrics"
    t.index ["export_id"], name: "index_export_resources_on_export_id"
  end

  create_table "exportables", force: :cascade do |t|
    t.bigint "export_id"
    t.string "uuid"
    t.string "model_type"
    t.bigint "model_id"
    t.index ["export_id"], name: "index_exportables_on_export_id"
    t.index ["uuid", "model_type"], name: "index_exportables_on_uuid_and_model_type"
  end

  create_table "exports", force: :cascade do |t|
    t.string "status"
    t.string "current_step_id"
    t.float "current_step_progress"
    t.bigint "workbench_id"
    t.bigint "referential_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "token_upload"
    t.string "type"
    t.datetime "notified_parent_at"
    t.integer "current_step", default: 0
    t.integer "total_steps", default: 0
    t.string "creator"
    t.string "notification_target"
    t.datetime "notified_recipients_at"
    t.bigint "user_id"
    t.bigint "publication_id"
    t.bigint "workgroup_id"
    t.hstore "options", default: {}
    t.index ["publication_id"], name: "index_exports_on_publication_id"
    t.index ["referential_id"], name: "index_exports_on_referential_id"
    t.index ["workbench_id"], name: "index_exports_on_workbench_id"
    t.index ["workgroup_id"], name: "index_exports_on_workgroup_id"
  end

  create_table "fare_products", force: :cascade do |t|
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "fare_provider_id"
    t.string "name"
    t.bigint "company_id"
    t.integer "price_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_fare_products_on_company_id"
    t.index ["fare_provider_id"], name: "index_fare_products_on_fare_provider_id"
  end

  create_table "fare_products_validities", force: :cascade do |t|
    t.bigint "fare_product_id", null: false
    t.bigint "fare_validity_id", null: false
    t.index ["fare_product_id"], name: "index_fare_products_validities_on_fare_product_id"
    t.index ["fare_validity_id"], name: "index_fare_products_validities_on_fare_validity_id"
  end

  create_table "fare_providers", force: :cascade do |t|
    t.string "short_name"
    t.bigint "workbench_id"
    t.bigint "fare_referential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.index ["fare_referential_id"], name: "index_fare_providers_on_fare_referential_id"
    t.index ["workbench_id"], name: "index_fare_providers_on_workbench_id"
  end

  create_table "fare_referentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fare_stop_areas_zones", force: :cascade do |t|
    t.bigint "fare_zone_id", null: false
    t.bigint "stop_area_id", null: false
    t.index ["fare_zone_id"], name: "index_fare_stop_areas_zones_on_fare_zone_id"
    t.index ["stop_area_id"], name: "index_fare_stop_areas_zones_on_stop_area_id"
  end

  create_table "fare_validities", force: :cascade do |t|
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "fare_provider_id"
    t.string "name"
    t.jsonb "expression"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fare_provider_id"], name: "index_fare_validities_on_fare_provider_id"
  end

  create_table "fare_zones", force: :cascade do |t|
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "fare_provider_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fare_provider_id"], name: "index_fare_zones_on_fare_provider_id"
  end

  create_table "footnotes", force: :cascade do |t|
    t.bigint "line_id"
    t.string "code"
    t.string "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
  end

  create_table "footnotes_vehicle_journeys", id: false, force: :cascade do |t|
    t.bigint "vehicle_journey_id"
    t.bigint "footnote_id"
  end

  create_table "group_of_lines", force: :cascade do |t|
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "comment"
    t.string "registration_number"
    t.bigint "line_referential_id"
    t.text "import_xml"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "metadata", default: {}
    t.bigint "line_provider_id"
    t.index ["line_provider_id"], name: "index_group_of_lines_on_line_provider_id"
    t.index ["line_referential_id"], name: "index_group_of_lines_on_line_referential_id"
    t.index ["objectid"], name: "group_of_lines_objectid_key", unique: true
  end

  create_table "group_of_lines_lines", id: false, force: :cascade do |t|
    t.bigint "group_of_line_id"
    t.bigint "line_id"
  end

  create_table "import_messages", force: :cascade do |t|
    t.string "criticity"
    t.string "message_key"
    t.hstore "message_attributes"
    t.bigint "import_id"
    t.bigint "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore "resource_attributes"
    t.index ["import_id"], name: "index_import_messages_on_import_id"
    t.index ["resource_id"], name: "index_import_messages_on_resource_id"
  end

  create_table "import_resources", force: :cascade do |t|
    t.bigint "import_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "resource_type"
    t.string "reference"
    t.string "name"
    t.hstore "metrics"
    t.bigint "referential_id"
    t.index ["import_id"], name: "index_import_resources_on_import_id"
    t.index ["referential_id"], name: "index_import_resources_on_referential_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string "status"
    t.string "current_step_id"
    t.float "current_step_progress"
    t.bigint "workbench_id"
    t.bigint "referential_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "token_download"
    t.string "type"
    t.bigint "parent_id"
    t.string "parent_type"
    t.datetime "notified_parent_at"
    t.integer "current_step", default: 0
    t.integer "total_steps", default: 0
    t.string "creator"
    t.jsonb "options", default: {}
    t.string "notification_target"
    t.datetime "notified_recipients_at"
    t.bigint "user_id"
    t.bigint "overlapping_referential_ids", default: [], array: true
    t.index ["referential_id"], name: "index_imports_on_referential_id"
    t.index ["workbench_id"], name: "index_imports_on_workbench_id"
  end

  create_table "journey_patterns", force: :cascade do |t|
    t.bigint "route_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "comment"
    t.string "registration_number"
    t.string "published_name"
    t.bigint "departure_stop_point_id"
    t.bigint "arrival_stop_point_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
    t.jsonb "costs", default: {}
    t.jsonb "metadata", default: {}
    t.jsonb "custom_field_values"
    t.bigint "shape_id"
    t.index ["checksum"], name: "index_journey_patterns_on_checksum"
    t.index ["custom_field_values"], name: "index_journey_patterns_on_custom_field_values", using: :gin
    t.index ["objectid"], name: "journey_patterns_objectid_key", unique: true
    t.index ["route_id"], name: "index_journey_patterns_on_route_id"
    t.index ["shape_id"], name: "index_journey_patterns_on_shape_id"
  end

  create_table "journey_patterns_stop_points", id: false, force: :cascade do |t|
    t.bigint "journey_pattern_id"
    t.bigint "stop_point_id"
    t.index ["journey_pattern_id"], name: "index_journey_pattern_id_on_journey_patterns_stop_points"
  end

  create_table "line_notices", force: :cascade do |t|
    t.bigint "line_referential_id"
    t.string "title"
    t.text "content"
    t.string "objectid", null: false
    t.text "import_xml"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "object_version"
    t.string "registration_number"
    t.bigint "line_provider_id"
    t.index ["line_provider_id"], name: "index_line_notices_on_line_provider_id"
  end

  create_table "line_notices_lines", id: false, force: :cascade do |t|
    t.bigint "line_notice_id", null: false
    t.bigint "line_id", null: false
    t.index ["line_notice_id", "line_id"], name: "index_line_notices_lines_on_line_notice_id_and_line_id"
  end

  create_table "line_providers", force: :cascade do |t|
    t.string "short_name", null: false
    t.bigint "workbench_id", null: false
    t.bigint "line_referential_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.index ["line_referential_id"], name: "index_line_providers_on_line_referential_id"
    t.index ["workbench_id"], name: "index_line_providers_on_workbench_id"
  end

  create_table "line_referential_memberships", force: :cascade do |t|
    t.bigint "organisation_id"
    t.bigint "line_referential_id"
    t.boolean "owner"
  end

  create_table "line_referentials", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "objectid_format"
  end

  create_table "line_routing_constraint_zones", force: :cascade do |t|
    t.string "name"
    t.bigint "line_ids", array: true
    t.bigint "stop_area_ids", array: true
    t.bigint "line_referential_id"
    t.bigint "line_provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_provider_id"], name: "index_line_routing_constraint_zones_on_line_provider_id"
    t.index ["line_referential_id"], name: "index_line_routing_constraint_zones_on_line_referential_id"
  end

  create_table "lines", force: :cascade do |t|
    t.bigint "network_id"
    t.bigint "company_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "number"
    t.string "published_name"
    t.string "transport_mode"
    t.string "registration_number"
    t.string "comment"
    t.boolean "flexible_service"
    t.string "url"
    t.string "color", limit: 6
    t.string "text_color", limit: 6
    t.bigint "line_referential_id"
    t.boolean "deactivated", default: false
    t.text "import_xml"
    t.string "transport_submode"
    t.bigint "secondary_company_ids", array: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "seasonal"
    t.jsonb "metadata", default: {}
    t.date "active_from"
    t.date "active_until"
    t.bigint "line_provider_id"
    t.boolean "is_referent", default: false
    t.bigint "referent_id"
    t.string "mobility_impaired_accessibility"
    t.string "wheelchair_accessibility"
    t.string "step_free_accessibility"
    t.string "escalator_free_accessibility"
    t.string "lift_free_accessibility"
    t.string "audible_signals_availability"
    t.string "visual_signs_availability"
    t.text "accessibility_limitation_description"
    t.index ["line_provider_id"], name: "index_lines_on_line_provider_id"
    t.index ["line_referential_id", "registration_number"], name: "index_lines_on_referential_id_and_registration_number"
    t.index ["line_referential_id"], name: "index_lines_on_line_referential_id"
    t.index ["objectid"], name: "lines_objectid_key", unique: true
    t.index ["referent_id"], name: "index_lines_on_referent_id"
    t.index ["registration_number"], name: "lines_registration_number_key"
    t.index ["secondary_company_ids"], name: "index_lines_on_secondary_company_ids", using: :gin
  end

  create_table "macro_context_runs", force: :cascade do |t|
    t.bigint "macro_list_run_id"
    t.string "name"
    t.jsonb "options", default: {}
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.index ["macro_list_run_id"], name: "index_macro_context_runs_on_macro_list_run_id"
  end

  create_table "macro_contexts", force: :cascade do |t|
    t.bigint "macro_list_id"
    t.string "name"
    t.jsonb "options", default: {}
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.index ["macro_list_id"], name: "index_macro_contexts_on_macro_list_id"
  end

  create_table "macro_list_runs", force: :cascade do |t|
    t.bigint "workbench_id"
    t.string "name"
    t.bigint "original_macro_list_id"
    t.bigint "referential_id"
    t.string "status"
    t.string "error_uuid"
    t.string "creator"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_status", null: false
    t.index ["original_macro_list_id"], name: "index_macro_list_runs_on_original_macro_list_id"
    t.index ["referential_id"], name: "index_macro_list_runs_on_referential_id"
    t.index ["workbench_id"], name: "index_macro_list_runs_on_workbench_id"
  end

  create_table "macro_lists", force: :cascade do |t|
    t.bigint "workbench_id"
    t.string "name"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workbench_id"], name: "index_macro_lists_on_workbench_id"
  end

  create_table "macro_messages", force: :cascade do |t|
    t.string "source_type"
    t.bigint "source_id"
    t.bigint "macro_run_id"
    t.string "message_key"
    t.string "criticity"
    t.jsonb "message_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["macro_run_id"], name: "index_macro_messages_on_macro_run_id"
    t.index ["source_type", "source_id"], name: "index_macro_messages_on_source_type_and_source_id"
  end

  create_table "macro_runs", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "macro_list_run_id"
    t.integer "position", null: false
    t.text "name"
    t.text "comments"
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "macro_context_run_id"
    t.index ["macro_context_run_id"], name: "index_macro_runs_on_macro_context_run_id"
    t.index ["macro_list_run_id", "position"], name: "index_macro_runs_on_macro_list_run_id_and_position", unique: true
    t.index ["macro_list_run_id"], name: "index_macro_runs_on_macro_list_run_id"
  end

  create_table "macros", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "macro_list_id"
    t.integer "position", null: false
    t.string "name"
    t.text "comments"
    t.jsonb "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "macro_context_id"
    t.index ["macro_context_id"], name: "index_macros_on_macro_context_id"
    t.index ["macro_list_id", "macro_context_id", "position"], name: "index_macros_position", unique: true
    t.index ["macro_list_id"], name: "index_macros_on_macro_list_id"
  end

  create_table "merges", force: :cascade do |t|
    t.bigint "workbench_id"
    t.bigint "referential_ids", array: true
    t.string "creator"
    t.string "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "new_id"
    t.string "notification_target"
    t.datetime "notified_recipients_at"
    t.bigint "user_id"
    t.string "merge_method", default: "legacy"
    t.index ["workbench_id"], name: "index_merges_on_workbench_id"
  end

  create_table "networks", force: :cascade do |t|
    t.string "objectid", null: false
    t.bigint "object_version"
    t.date "version_date"
    t.string "description"
    t.string "name"
    t.string "registration_number"
    t.string "source_name"
    t.string "source_type"
    t.string "source_identifier"
    t.string "comment"
    t.text "import_xml"
    t.bigint "line_referential_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "metadata", default: {}
    t.bigint "line_provider_id"
    t.index ["line_provider_id"], name: "index_networks_on_line_provider_id"
    t.index ["line_referential_id"], name: "index_networks_on_line_referential_id"
    t.index ["objectid"], name: "networks_objectid_key", unique: true
    t.index ["registration_number"], name: "networks_registration_number_key"
  end

  create_table "notification_rules", force: :cascade do |t|
    t.string "notification_type"
    t.daterange "period"
    t.bigint "workbench_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_ids", default: [], array: true
    t.string "external_email"
    t.integer "priority", default: 10
    t.string "target_type"
    t.bigint "line_ids", default: [], array: true
    t.string "rule_type"
    t.string "operation_statuses", default: [], array: true
    t.index ["workbench_id"], name: "index_notification_rules_on_workbench_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "data_format", default: "neptune"
    t.string "code"
    t.datetime "synced_at"
    t.hstore "sso_attributes"
    t.string "custom_view"
    t.string "features", default: [], array: true
    t.index ["code"], name: "index_organisations_on_code", unique: true
  end

  create_table "point_of_interest_categories", force: :cascade do |t|
    t.bigint "shape_referential_id", null: false
    t.bigint "shape_provider_id", null: false
    t.bigint "parent_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_point_of_interest_categories_on_parent_id"
    t.index ["shape_provider_id"], name: "index_point_of_interest_categories_on_shape_provider_id"
    t.index ["shape_referential_id"], name: "index_point_of_interest_categories_on_shape_referential_id"
  end

  create_table "point_of_interest_hours", force: :cascade do |t|
    t.bigint "point_of_interest_id", null: false
    t.time "opening_time_of_day", null: false
    t.time "closing_time_of_day", null: false
    t.bit "week_days", limit: 7, default: "1111111"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["point_of_interest_id"], name: "index_point_of_interest_hours_on_point_of_interest_id"
  end

  create_table "point_of_interests", force: :cascade do |t|
    t.bigint "shape_referential_id", null: false
    t.bigint "shape_provider_id", null: false
    t.bigint "point_of_interest_category_id", null: false
    t.string "name", null: false
    t.string "url"
    t.geography "position", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "address_line_1"
    t.string "zip_code"
    t.string "city_name"
    t.string "country"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "postal_region"
    t.index ["point_of_interest_category_id"], name: "index_point_of_interests_on_point_of_interest_category_id"
    t.index ["shape_provider_id"], name: "index_point_of_interests_on_shape_provider_id"
    t.index ["shape_referential_id"], name: "index_point_of_interests_on_shape_referential_id"
  end

  create_table "processing_rules", force: :cascade do |t|
    t.bigint "workgroup_id"
    t.bigint "workbench_id"
    t.string "type", null: false
    t.string "processable_type"
    t.bigint "processable_id"
    t.string "operation_step"
    t.bigint "target_workbench_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processable_type", "processable_id"], name: "index_processing_rules_on_processable_type_and_processable_id"
    t.index ["workbench_id"], name: "index_processing_rules_on_workbench_id"
    t.index ["workgroup_id"], name: "index_processing_rules_on_workgroup_id"
  end

  create_table "processings", force: :cascade do |t|
    t.string "step"
    t.bigint "workbench_id"
    t.bigint "workgroup_id"
    t.string "operation_type"
    t.bigint "operation_id"
    t.string "processed_type"
    t.bigint "processed_id"
    t.bigint "processing_rule_id"
    t.index ["operation_type", "operation_id"], name: "index_processings_on_operation_type_and_operation_id"
    t.index ["processed_type", "processed_id"], name: "index_processings_on_processed_type_and_processed_id"
    t.index ["processing_rule_id"], name: "index_processings_on_processing_rule_id"
    t.index ["workbench_id"], name: "index_processings_on_workbench_id"
    t.index ["workgroup_id"], name: "index_processings_on_workgroup_id"
  end

  create_table "publication_api_keys", force: :cascade do |t|
    t.string "name"
    t.string "token"
    t.bigint "publication_api_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_api_id"], name: "index_publication_api_keys_on_publication_api_id"
  end

  create_table "publication_api_sources", force: :cascade do |t|
    t.bigint "publication_id"
    t.bigint "publication_api_id"
    t.string "key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "export_id"
    t.index ["publication_api_id"], name: "index_publication_api_sources_on_publication_api_id"
    t.index ["publication_id", "key"], name: "index_publication_api_sources_on_publication_id_and_key"
    t.index ["publication_id"], name: "index_publication_api_sources_on_publication_id"
  end

  create_table "publication_apis", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "workgroup_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false
    t.index ["workgroup_id"], name: "index_publication_apis_on_workgroup_id"
  end

  create_table "publication_setups", force: :cascade do |t|
    t.bigint "workgroup_id"
    t.hstore "export_options"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "force_daily_publishing", default: false
    t.index ["workgroup_id"], name: "index_publication_setups_on_workgroup_id"
  end

  create_table "publications", force: :cascade do |t|
    t.bigint "publication_setup_id"
    t.string "parent_type"
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.boolean "rollback"
    t.index ["parent_type", "parent_id"], name: "index_publications_on_parent_type_and_parent_id"
    t.index ["publication_setup_id"], name: "index_publications_on_publication_setup_id"
  end

  create_table "raw_imports", force: :cascade do |t|
    t.string "model_type"
    t.bigint "model_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_id", "model_type"], name: "index_raw_imports_on_model_id_and_model_type", unique: true
  end

  create_table "referential_clonings", force: :cascade do |t|
    t.string "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.bigint "source_referential_id"
    t.bigint "target_referential_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_referential_id"], name: "index_referential_clonings_on_source_referential_id"
    t.index ["target_referential_id"], name: "index_referential_clonings_on_target_referential_id"
  end

  create_table "referential_codes", force: :cascade do |t|
    t.bigint "code_space_id", null: false
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_space_id", "resource_type", "resource_id", "value"], name: "index_referential_codes_on_space_resource_and_value", unique: true
    t.index ["code_space_id", "resource_type", "resource_id"], name: "index_referential_codes_on_space_and_resource"
    t.index ["code_space_id"], name: "index_referential_codes_on_code_space_id"
    t.index ["resource_type", "resource_id"], name: "index_referential_codes_on_resource_type_and_resource_id"
  end

  create_table "referential_metadata", force: :cascade do |t|
    t.bigint "referential_id"
    t.bigint "line_ids", array: true
    t.bigint "referential_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.daterange "periodes", array: true
    t.datetime "flagged_urgent_at"
    t.integer "priority"
    t.index ["line_ids"], name: "index_referential_metadata_on_line_ids", using: :gin
    t.index ["referential_id"], name: "index_referential_metadata_on_referential_id"
    t.index ["referential_source_id"], name: "index_referential_metadata_on_referential_source_id"
  end

  create_table "referential_suites", force: :cascade do |t|
    t.bigint "new_id"
    t.bigint "current_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_id"], name: "index_referential_suites_on_current_id"
    t.index ["new_id"], name: "index_referential_suites_on_new_id"
  end

  create_table "referentials", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "prefix"
    t.string "projection_type"
    t.string "time_zone"
    t.string "bounds"
    t.bigint "organisation_id"
    t.text "geographical_bounds"
    t.bigint "user_id"
    t.string "user_name"
    t.string "data_format"
    t.bigint "line_referential_id"
    t.bigint "stop_area_referential_id"
    t.bigint "workbench_id"
    t.datetime "archived_at"
    t.bigint "created_from_id"
    t.boolean "ready", default: false
    t.bigint "referential_suite_id"
    t.string "objectid_format"
    t.datetime "merged_at"
    t.datetime "failed_at"
    t.integer "vehicle_journeys_count"
    t.index ["created_from_id"], name: "index_referentials_on_created_from_id"
    t.index ["referential_suite_id"], name: "index_referentials_on_referential_suite_id"
    t.index ["slug"], name: "index_referentials_on_slug", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "line_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "comment"
    t.bigint "opposite_route_id"
    t.string "published_name"
    t.string "number"
    t.string "direction"
    t.string "wayback"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
    t.jsonb "costs", default: {}
    t.jsonb "metadata"
    t.index ["checksum"], name: "index_routes_on_checksum"
    t.index ["line_id"], name: "index_routes_on_line_id"
    t.index ["objectid"], name: "routes_objectid_key", unique: true
  end

  create_table "routing_constraint_zones", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.bigint "route_id"
    t.bigint "stop_point_ids", array: true
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
    t.jsonb "metadata", default: {}
  end

  create_table "saved_searches", force: :cascade do |t|
    t.bigint "workbench_id", null: false
    t.string "search_type", null: false
    t.string "name", null: false
    t.string "creator"
    t.datetime "last_used_at"
    t.jsonb "search_attributes", default: {}
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workbench_id"], name: "index_saved_searches_on_workbench_id"
  end

  create_table "sequences", force: :cascade do |t|
    t.string "name"
    t.string "sequence_type"
    t.integer "range_start"
    t.integer "range_end"
    t.text "description"
    t.bigint "workbench_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "static_list", default: [], array: true
    t.index ["workbench_id"], name: "index_sequences_on_workbench_id"
  end

  create_table "service_counts", force: :cascade do |t|
    t.bigint "journey_pattern_id"
    t.bigint "route_id"
    t.bigint "line_id"
    t.date "date"
    t.integer "count", default: 0
    t.index ["journey_pattern_id"], name: "journey_pattern_id"
    t.index ["line_id"], name: "line_id"
    t.index ["route_id"], name: "route_id"
  end

  create_table "service_facility_sets", force: :cascade do |t|
    t.string "name"
    t.string "associated_services", default: [], array: true
    t.bigint "referential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referential_id"], name: "index_service_facility_sets_on_referential_id"
  end

  create_table "shape_providers", force: :cascade do |t|
    t.string "short_name", null: false
    t.bigint "workbench_id", null: false
    t.bigint "shape_referential_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shape_referential_id"], name: "index_shape_providers_on_shape_referential_id"
    t.index ["workbench_id"], name: "index_shape_providers_on_workbench_id"
  end

  create_table "shape_referentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shapes", force: :cascade do |t|
    t.string "name"
    t.geometry "geometry", limit: {:srid=>4326, :type=>"line_string"}
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "shape_referential_id", null: false
    t.bigint "shape_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shape_provider_id"], name: "index_shapes_on_shape_provider_id"
    t.index ["shape_referential_id"], name: "index_shapes_on_shape_referential_id"
  end

  create_table "source_retrievals", force: :cascade do |t|
    t.bigint "workbench_id"
    t.bigint "source_id"
    t.bigint "import_id"
    t.string "status"
    t.string "error_uuid"
    t.string "creator"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_status", null: false
    t.string "message_key"
    t.index ["import_id"], name: "index_source_retrievals_on_import_id"
    t.index ["source_id"], name: "index_source_retrievals_on_source_id"
    t.index ["workbench_id"], name: "index_source_retrievals_on_workbench_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name"
    t.bigint "workbench_id"
    t.string "url"
    t.string "downloader_type"
    t.jsonb "downloader_options", default: {}
    t.string "checksum"
    t.jsonb "import_options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ignore_checksum", default: false
    t.time "retrieval_time_of_day"
    t.bigint "scheduled_job_id"
    t.string "retrieval_frequency"
    t.bit "retrieval_days_of_week", limit: 7, default: "1111111"
    t.index ["scheduled_job_id"], name: "index_sources_on_scheduled_job_id"
    t.index ["workbench_id"], name: "index_sources_on_workbench_id"
  end

  create_table "stop_area_providers", force: :cascade do |t|
    t.string "objectid"
    t.string "name"
    t.bigint "stop_area_referential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "workbench_id"
    t.index ["workbench_id"], name: "index_stop_area_providers_on_workbench_id"
  end

  create_table "stop_area_referential_memberships", force: :cascade do |t|
    t.bigint "organisation_id"
    t.bigint "stop_area_referential_id"
    t.boolean "owner"
  end

  create_table "stop_area_referentials", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "objectid_format"
    t.string "registration_number_format"
    t.jsonb "locales", default: [{"code"=>"fr_FR", "default"=>true}, {"code"=>"en_UK", "default"=>true}, {"code"=>"nl_NL", "default"=>true}, {"code"=>"es_ES", "default"=>true}, {"code"=>"it_IT", "default"=>true}, {"code"=>"de_DE", "default"=>true}], array: true
    t.jsonb "stops_selection_displayed_fields", default: {"local_id"=>true}
    t.jsonb "route_edition_available_stops", default: {"gdl"=>false, "lda"=>false, "zdep"=>true, "zdlp"=>false}
  end

  create_table "stop_area_routing_constraints", force: :cascade do |t|
    t.bigint "from_id"
    t.bigint "to_id"
    t.boolean "both_way"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "checksum"
    t.text "checksum_source"
    t.bigint "stop_area_referential_id"
    t.bigint "stop_area_provider_id"
    t.index ["from_id"], name: "index_stop_area_routing_constraints_on_from_id"
    t.index ["stop_area_provider_id"], name: "index_stop_area_routing_constraints_on_stop_area_provider_id"
    t.index ["stop_area_referential_id"], name: "index_stop_area_routing_constraints_on_stop_area_referential_id"
    t.index ["to_id"], name: "index_stop_area_routing_constraints_on_to_id"
  end

  create_table "stop_areas", force: :cascade do |t|
    t.bigint "parent_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "name"
    t.string "comment"
    t.string "area_type"
    t.string "registration_number"
    t.string "nearest_topic_name"
    t.decimal "longitude", precision: 19, scale: 16
    t.decimal "latitude", precision: 19, scale: 16
    t.string "long_lat_type"
    t.string "country_code"
    t.string "street_name"
    t.string "zip_code"
    t.string "city_name"
    t.string "url"
    t.string "time_zone"
    t.bigint "stop_area_referential_id"
    t.string "status"
    t.text "import_xml"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "stif_type"
    t.integer "waiting_time"
    t.string "kind"
    t.jsonb "localized_names"
    t.datetime "confirmed_at"
    t.jsonb "custom_field_values"
    t.jsonb "metadata", default: {}
    t.bigint "referent_id"
    t.boolean "is_referent", default: false
    t.string "postal_region"
    t.bigint "stop_area_provider_id"
    t.string "public_code"
    t.float "compass_bearing"
    t.string "mobility_impaired_accessibility"
    t.string "wheelchair_accessibility"
    t.string "step_free_accessibility"
    t.string "escalator_free_accessibility"
    t.string "lift_free_accessibility"
    t.string "audible_signals_availability"
    t.string "visual_signs_availability"
    t.text "accessibility_limitation_description"
    t.string "transport_mode"
    t.index ["custom_field_values"], name: "index_stop_areas_on_custom_field_values", using: :gin
    t.index ["name"], name: "index_stop_areas_on_name"
    t.index ["objectid", "stop_area_referential_id"], name: "stop_areas_objectid_key", unique: true
    t.index ["parent_id"], name: "index_stop_areas_on_parent_id"
    t.index ["stop_area_provider_id"], name: "index_stop_areas_on_stop_area_provider_id"
    t.index ["stop_area_referential_id", "registration_number"], name: "index_stop_areas_on_referential_id_and_registration_number"
    t.index ["stop_area_referential_id"], name: "index_stop_areas_on_stop_area_referential_id"
  end

  create_table "stop_points", force: :cascade do |t|
    t.bigint "route_id"
    t.bigint "stop_area_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.integer "position"
    t.string "for_boarding"
    t.string "for_alighting"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "metadata", default: {}
    t.index ["objectid"], name: "stop_points_objectid_key", unique: true
    t.index ["route_id"], name: "index_stop_points_on_route_id"
  end

  create_table "time_table_dates", force: :cascade do |t|
    t.bigint "time_table_id", null: false
    t.date "date"
    t.boolean "in_out"
    t.string "checksum"
    t.text "checksum_source"
    t.index ["date", "time_table_id"], name: "uniq_date_per_time_table", unique: true
    t.index ["time_table_id"], name: "index_time_table_dates_on_time_table_id"
  end

  create_table "time_table_periods", force: :cascade do |t|
    t.bigint "time_table_id", null: false
    t.date "period_start"
    t.date "period_end"
    t.string "checksum"
    t.text "checksum_source"
    t.index ["period_start", "period_end", "time_table_id"], name: "uniq_period_start_and_period_end_per_time_table", unique: true
    t.index ["period_start", "period_end"], name: "index_time_table_periods_on_period_start_and_period_end"
    t.index ["time_table_id"], name: "index_time_table_periods_on_time_table_id"
  end

  create_table "time_tables", force: :cascade do |t|
    t.string "objectid", null: false
    t.bigint "object_version", default: 1
    t.string "version"
    t.string "comment"
    t.integer "int_day_types", default: 0
    t.date "start_date"
    t.date "end_date"
    t.bigint "calendar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "color"
    t.bigint "created_from_id"
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
    t.jsonb "metadata", default: {}
    t.index ["calendar_id"], name: "index_time_tables_on_calendar_id"
    t.index ["created_from_id"], name: "index_time_tables_on_created_from_id"
    t.index ["objectid"], name: "time_tables_objectid_key", unique: true
  end

  create_table "time_tables_vehicle_journeys", id: false, force: :cascade do |t|
    t.bigint "time_table_id"
    t.bigint "vehicle_journey_id"
    t.index ["time_table_id"], name: "index_time_tables_vehicle_journeys_on_time_table_id"
    t.index ["vehicle_journey_id"], name: "index_time_tables_vehicle_journeys_on_vehicle_journey_id"
  end

  create_table "time_zones", force: :cascade do |t|
    t.string "name"
    t.integer "utc_offset"
    t.index ["name"], name: "index_time_zones_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "organisation_id"
    t.string "name"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "authentication_token"
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.datetime "invitation_created_at"
    t.string "username"
    t.datetime "synced_at"
    t.string "permissions", array: true
    t.string "profile"
    t.string "user_locale"
    t.string "time_zone", limit: 255, default: "Paris"
    t.boolean "enable_internal_password_authentication", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["profile"], name: "index_users_on_profile"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vehicle_journey_at_stops", force: :cascade do |t|
    t.bigint "vehicle_journey_id"
    t.bigint "stop_point_id"
    t.string "connecting_service_id"
    t.string "boarding_alighting_possibility"
    t.time "arrival_time"
    t.time "departure_time"
    t.string "for_boarding"
    t.string "for_alighting"
    t.integer "departure_day_offset", default: 0
    t.integer "arrival_day_offset", default: 0
    t.string "checksum"
    t.text "checksum_source"
    t.bigint "stop_area_id"
    t.index ["stop_area_id"], name: "index_vehicle_journey_at_stops_on_stop_area_id"
    t.index ["stop_point_id"], name: "index_vehicle_journey_at_stops_on_stop_pointid"
    t.index ["vehicle_journey_id"], name: "index_vehicle_journey_at_stops_on_vehicle_journey_id"
  end

  create_table "vehicle_journeys", force: :cascade do |t|
    t.bigint "route_id"
    t.bigint "journey_pattern_id"
    t.bigint "company_id"
    t.string "objectid", null: false
    t.bigint "object_version"
    t.string "comment"
    t.string "transport_mode"
    t.string "published_journey_name"
    t.string "published_journey_identifier"
    t.string "facility"
    t.string "vehicle_type_identifier"
    t.bigint "number"
    t.boolean "mobility_restricted_suitability"
    t.boolean "flexible_service"
    t.integer "journey_category", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "checksum"
    t.text "checksum_source"
    t.string "data_source_ref"
    t.jsonb "custom_field_values", default: {}
    t.jsonb "metadata", default: {}
    t.bigint "ignored_routing_contraint_zone_ids", default: [], array: true
    t.bigint "ignored_stop_area_routing_constraint_ids", default: [], array: true
    t.bigint "line_notice_ids", default: [], array: true
    t.index ["checksum"], name: "index_vehicle_journeys_on_checksum"
    t.index ["custom_field_values"], name: "index_vehicle_journeys_on_custom_field_values", using: :gin
    t.index ["journey_pattern_id"], name: "index_vehicle_journeys_on_journey_pattern_id"
    t.index ["objectid"], name: "vehicle_journeys_objectid_key", unique: true
    t.index ["route_id"], name: "index_vehicle_journeys_on_route_id"
  end

  create_table "waypoints", force: :cascade do |t|
    t.string "name"
    t.integer "position", null: false
    t.string "waypoint_type", null: false
    t.bigint "shape_id"
    t.float "coordinates", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "stop_area_id"
    t.index ["shape_id"], name: "index_waypoints_on_shape_id"
    t.index ["stop_area_id"], name: "index_waypoints_on_stop_area_id"
  end

  create_table "workbenches", force: :cascade do |t|
    t.string "name"
    t.bigint "organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "line_referential_id"
    t.bigint "stop_area_referential_id"
    t.bigint "output_id"
    t.string "objectid_format"
    t.bigint "workgroup_id"
    t.string "prefix"
    t.bigint "locked_referential_to_aggregate_id"
    t.string "restrictions", default: [], array: true
    t.integer "priority", default: 1
    t.string "invitation_code"
    t.index ["line_referential_id"], name: "index_workbenches_on_line_referential_id"
    t.index ["locked_referential_to_aggregate_id"], name: "index_workbenches_on_locked_referential_to_aggregate_id"
    t.index ["organisation_id"], name: "index_workbenches_on_organisation_id"
    t.index ["stop_area_referential_id"], name: "index_workbenches_on_stop_area_referential_id"
    t.index ["workgroup_id"], name: "index_workbenches_on_workgroup_id"
  end

  create_table "workgroups", force: :cascade do |t|
    t.string "name"
    t.bigint "line_referential_id"
    t.bigint "stop_area_referential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "import_types", default: [], array: true
    t.string "export_types", default: [], array: true
    t.bigint "owner_id"
    t.bigint "output_id"
    t.time "nightly_aggregate_time", default: "2000-01-01 00:00:00"
    t.boolean "nightly_aggregate_enabled", default: false
    t.datetime "nightly_aggregated_at"
    t.datetime "aggregated_at"
    t.string "nightly_aggregate_notification_target", default: "none"
    t.datetime "deleted_at"
    t.jsonb "transport_modes", default: {"air"=>["undefined", "airshipService", "domesticCharterFlight", "domesticFlight", "domesticScheduledFlight", "helicopterService", "intercontinentalCharterFlight", "intercontinentalFlight", "internationalCharterFlight", "internationalFlight", "roundTripCharterFlight", "schengenAreaFlight", "shortHaulInternationalFlight", "shuttleFlight", "sightseeingFlight"], "bus"=>["undefined", "airportLinkBus", "demandAndResponseBus", "expressBus", "highFrequencyBus", "localBus", "mobilityBusForRegisteredDisabled", "mobilityBus", "nightBus", "postBus", "railReplacementBus", "regionalBus", "schoolAndPublicServiceBus", "schoolBus", "shuttleBus", "sightseeingBus", "specialNeedsBus"], "rail"=>["undefined", "carTransportRailService", "crossCountryRail", "highSpeedRail", "international", "interregionalRail", "local", "longDistance", "nightTrain", "rackAndPinionRailway", "railShuttle", "regionalRail", "replacementRailService", "sleeperRailService", "specialTrain", "suburbanRailway", "touristRailway"], "taxi"=>["undefined", "allTaxiServices", "bikeTaxi", "blackCab", "communalTaxi", "miniCab", "railTaxi", "waterTaxi"], "tram"=>["undefined", "cityTram", "localTram", "regionalTram", "shuttleTram", "sightseeingTram", "tramTrain"], "coach"=>["undefined", "commuterCoach", "internationalCoach", "nationalCoach", "regionalCoach", "shuttleCoach", "sightseeingCoach", "specialCoach", "touristCoach"], "metro"=>["undefined", "metro", "tube", "urbanRailway"], "water"=>["undefined", "internationalCarFerry", "nationalCarFerry", "regionalCarFerry", "localCarFerry", "internationalPassengerFerry", "nationalPassengerFerry", "regionalPassengerFerry", "localPassengerFerry", "postBoat", "trainFerry", "roadFerryLink", "airportBoatLink", "highSpeedVehicleService", "highSpeedPassengerService", "sightseeingService", "schoolBoat", "cableFerry", "riverBus", "scheduledFerry", "shuttleFerryService"], "hireCar"=>["undefined", "allHireVehicles", "hireCar", "hireCycle", "hireMotorbike", "hireVan"], "funicular"=>["undefined", "allFunicularServices", "funicular"], "telecabin"=>["undefined", "cableCar", "chairLift", "dragLift", "lift", "telecabinLink", "telecabin"]}
    t.integer "maximum_data_age", default: 0
    t.boolean "enable_purge_merged_data", default: false
    t.bigint "shape_referential_id", null: false
    t.bit "nightly_aggregate_days", limit: 7, default: "1111111"
    t.string "description"
    t.bigint "fare_referential_id", null: false
    t.index ["fare_referential_id"], name: "index_workgroups_on_fare_referential_id"
    t.index ["shape_referential_id"], name: "index_workgroups_on_shape_referential_id"
  end

  add_foreign_key "authentications", "organisations"
  add_foreign_key "calendars", "workbenches"
  add_foreign_key "control_runs", "control_context_runs"
  add_foreign_key "controls", "control_contexts"
  add_foreign_key "custom_fields", "custom_field_groups"
  add_foreign_key "exports", "workgroups"
  add_foreign_key "group_of_lines_lines", "group_of_lines", name: "groupofline_group_fkey", on_delete: :cascade
  add_foreign_key "journey_patterns", "routes", name: "jp_route_fkey", on_delete: :cascade
  add_foreign_key "journey_patterns", "stop_points", column: "arrival_stop_point_id", name: "arrival_point_fkey", on_delete: :nullify
  add_foreign_key "journey_patterns", "stop_points", column: "departure_stop_point_id", name: "departure_point_fkey", on_delete: :nullify
  add_foreign_key "journey_patterns_stop_points", "journey_patterns", name: "jpsp_jp_fkey", on_delete: :cascade
  add_foreign_key "journey_patterns_stop_points", "stop_points", name: "jpsp_stoppoint_fkey", on_delete: :cascade
  add_foreign_key "macro_runs", "macro_context_runs"
  add_foreign_key "macros", "macro_contexts"
  add_foreign_key "point_of_interest_categories", "point_of_interest_categories", column: "parent_id"
  add_foreign_key "referentials", "referential_suites"
  add_foreign_key "routes", "routes", column: "opposite_route_id", name: "route_opposite_route_fkey"
  add_foreign_key "stop_areas", "stop_areas", column: "parent_id", name: "area_parent_fkey", on_delete: :nullify
  add_foreign_key "time_table_dates", "time_tables", name: "tm_date_fkey", on_delete: :cascade
  add_foreign_key "time_table_periods", "time_tables", name: "tm_period_fkey", on_delete: :cascade
  add_foreign_key "time_tables_vehicle_journeys", "time_tables", name: "vjtm_tm_fkey", on_delete: :cascade
  add_foreign_key "time_tables_vehicle_journeys", "vehicle_journeys", name: "vjtm_vj_fkey", on_delete: :cascade
  add_foreign_key "vehicle_journey_at_stops", "stop_points", name: "vjas_sp_fkey", on_delete: :cascade
  add_foreign_key "vehicle_journey_at_stops", "vehicle_journeys", name: "vjas_vj_fkey", on_delete: :cascade
  add_foreign_key "vehicle_journeys", "journey_patterns", name: "vj_jp_fkey", on_delete: :cascade
  add_foreign_key "vehicle_journeys", "routes", name: "vj_route_fkey", on_delete: :cascade
end
