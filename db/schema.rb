# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170307155042) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "access_links", force: true do |t|
    t.integer  "access_point_id",                        limit: 8
    t.integer  "stop_area_id",                           limit: 8
    t.string   "objectid",                                                                  null: false
    t.integer  "object_version",                         limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.decimal  "link_distance",                                    precision: 19, scale: 2
    t.boolean  "lift_availability"
    t.boolean  "mobility_restricted_suitability"
    t.boolean  "stairs_availability"
    t.time     "default_duration"
    t.time     "frequent_traveller_duration"
    t.time     "occasional_traveller_duration"
    t.time     "mobility_restricted_traveller_duration"
    t.string   "link_type"
    t.integer  "int_user_needs"
    t.string   "link_orientation"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_links", ["objectid"], :name => "access_links_objectid_key", :unique => true

  create_table "access_points", force: true do |t|
    t.string   "objectid"
    t.integer  "object_version",                  limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.decimal  "longitude",                                 precision: 19, scale: 16
    t.decimal  "latitude",                                  precision: 19, scale: 16
    t.string   "long_lat_type"
    t.string   "country_code"
    t.string   "street_name"
    t.string   "contained_in"
    t.time     "openning_time"
    t.time     "closing_time"
    t.string   "access_type"
    t.boolean  "lift_availability"
    t.boolean  "mobility_restricted_suitability"
    t.boolean  "stairs_availability"
    t.integer  "stop_area_id",                    limit: 8
    t.string   "zip_code"
    t.string   "city_name"
    t.text     "import_xml"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_points", ["objectid"], :name => "access_points_objectid_key", :unique => true

  create_table "api_keys", force: true do |t|
    t.integer  "referential_id", limit: 8
    t.string   "token"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "calendars", force: true do |t|
    t.string    "name"
    t.string    "short_name"
    t.daterange "date_ranges",               array: true
    t.date      "dates",                     array: true
    t.boolean   "shared"
    t.integer   "organisation_id", limit: 8
    t.datetime  "created_at"
    t.datetime  "updated_at"
  end

  add_index "calendars", ["organisation_id"], :name => "index_calendars_on_organisation_id"
  add_index "calendars", ["short_name"], :name => "index_calendars_on_short_name", :unique => true

  create_table "clean_up_results", force: true do |t|
    t.string   "message_key"
    t.hstore   "message_attributs"
    t.integer  "clean_up_id",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clean_up_results", ["clean_up_id"], :name => "index_clean_up_results_on_clean_up_id"

  create_table "clean_ups", force: true do |t|
    t.string   "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "referential_id", limit: 8
    t.datetime "begin_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "end_date"
  end

  add_index "clean_ups", ["referential_id"], :name => "index_clean_ups_on_referential_id"

  create_table "companies", force: true do |t|
    t.string   "objectid",                            null: false
    t.integer  "object_version",            limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "short_name"
    t.string   "organizational_unit"
    t.string   "operating_department_name"
    t.string   "code"
    t.string   "phone"
    t.string   "fax"
    t.string   "email"
    t.string   "registration_number"
    t.string   "url"
    t.string   "time_zone"
    t.integer  "line_referential_id",       limit: 8
    t.text     "import_xml"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "companies", ["line_referential_id"], :name => "index_companies_on_line_referential_id"
  add_index "companies", ["objectid"], :name => "companies_objectid_key", :unique => true
  add_index "companies", ["registration_number"], :name => "companies_registration_number_key"

  create_table "connection_links", force: true do |t|
    t.integer  "departure_id",                           limit: 8
    t.integer  "arrival_id",                             limit: 8
    t.string   "objectid",                                                                  null: false
    t.integer  "object_version",                         limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.decimal  "link_distance",                                    precision: 19, scale: 2
    t.string   "link_type"
    t.time     "default_duration"
    t.time     "frequent_traveller_duration"
    t.time     "occasional_traveller_duration"
    t.time     "mobility_restricted_traveller_duration"
    t.boolean  "mobility_restricted_suitability"
    t.boolean  "stairs_availability"
    t.boolean  "lift_availability"
    t.integer  "int_user_needs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "connection_links", ["objectid"], :name => "connection_links_objectid_key", :unique => true

  create_table "exports", force: true do |t|
    t.integer  "referential_id",  limit: 8
    t.string   "status"
    t.string   "type"
    t.string   "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "references_type"
    t.string   "reference_ids"
  end

  add_index "exports", ["referential_id"], :name => "index_exports_on_referential_id"

  create_table "facilities", force: true do |t|
    t.integer  "stop_area_id",       limit: 8
    t.integer  "line_id",            limit: 8
    t.integer  "connection_link_id", limit: 8
    t.integer  "stop_point_id",      limit: 8
    t.string   "objectid",                                               null: false
    t.integer  "object_version",     limit: 8
    t.datetime "creation_time"
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.string   "description"
    t.boolean  "free_access"
    t.decimal  "longitude",                    precision: 19, scale: 16
    t.decimal  "latitude",                     precision: 19, scale: 16
    t.string   "long_lat_type"
    t.decimal  "x",                            precision: 19, scale: 2
    t.decimal  "y",                            precision: 19, scale: 2
    t.string   "projection_type"
    t.string   "country_code"
    t.string   "street_name"
    t.string   "contained_in"
  end

  add_index "facilities", ["objectid"], :name => "facilities_objectid_key", :unique => true

  create_table "facilities_features", id: false, force: true do |t|
    t.integer "facility_id", limit: 8
    t.integer "choice_code"
  end

  create_table "footnotes", force: true do |t|
    t.integer  "line_id",    limit: 8
    t.string   "code"
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "footnotes_vehicle_journeys", id: false, force: true do |t|
    t.integer "vehicle_journey_id", limit: 8
    t.integer "footnote_id",        limit: 8
  end

  create_table "group_of_lines", force: true do |t|
    t.string   "objectid",                      null: false
    t.integer  "object_version",      limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.string   "registration_number"
    t.integer  "line_referential_id", limit: 8
    t.text     "import_xml"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "group_of_lines", ["line_referential_id"], :name => "index_group_of_lines_on_line_referential_id"
  add_index "group_of_lines", ["objectid"], :name => "group_of_lines_objectid_key", :unique => true

  create_table "group_of_lines_lines", id: false, force: true do |t|
    t.integer "group_of_line_id", limit: 8
    t.integer "line_id",          limit: 8
  end

  create_table "import_messages", force: true do |t|
    t.integer  "criticity"
    t.string   "message_key"
    t.hstore   "message_attributs"
    t.integer  "import_id",           limit: 8
    t.integer  "resource_id",         limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "resource_attributes"
  end

  add_index "import_messages", ["import_id"], :name => "index_import_messages_on_import_id"
  add_index "import_messages", ["resource_id"], :name => "index_import_messages_on_resource_id"

  create_table "import_resources", force: true do |t|
    t.integer  "import_id",  limit: 8
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "reference"
    t.string   "name"
    t.hstore   "metrics"
  end

  add_index "import_resources", ["import_id"], :name => "index_import_resources_on_import_id"

  create_table "imports", force: true do |t|
    t.string   "status"
    t.string   "current_step_id"
    t.float    "current_step_progress"
    t.integer  "workbench_id",          limit: 8
    t.integer  "referential_id",        limit: 8
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file"
    t.date     "started_at"
    t.date     "ended_at"
    t.string   "token_download"
  end

  add_index "imports", ["referential_id"], :name => "index_imports_on_referential_id"
  add_index "imports", ["workbench_id"], :name => "index_imports_on_workbench_id"

  create_table "journey_frequencies", force: true do |t|
    t.integer  "vehicle_journey_id",         limit: 8
    t.time     "scheduled_headway_interval",                           null: false
    t.time     "first_departure_time",                                 null: false
    t.time     "last_departure_time"
    t.boolean  "exact_time",                           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "timeband_id",                limit: 8
  end

  add_index "journey_frequencies", ["timeband_id"], :name => "index_journey_frequencies_on_timeband_id"
  add_index "journey_frequencies", ["vehicle_journey_id"], :name => "index_journey_frequencies_on_vehicle_journey_id"

  create_table "journey_pattern_sections", force: true do |t|
    t.integer  "journey_pattern_id", limit: 8, null: false
    t.integer  "route_section_id",   limit: 8, null: false
    t.integer  "rank",                         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journey_pattern_sections", ["journey_pattern_id", "route_section_id", "rank"], :name => "index_jps_on_journey_pattern_id_and_route_section_id_and_rank", :unique => true
  add_index "journey_pattern_sections", ["journey_pattern_id"], :name => "index_journey_pattern_sections_on_journey_pattern_id"
  add_index "journey_pattern_sections", ["route_section_id"], :name => "index_journey_pattern_sections_on_route_section_id"

  create_table "journey_patterns", force: true do |t|
    t.integer  "route_id",                limit: 8
    t.string   "objectid",                                      null: false
    t.integer  "object_version",          limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.string   "registration_number"
    t.string   "published_name"
    t.integer  "departure_stop_point_id", limit: 8
    t.integer  "arrival_stop_point_id",   limit: 8
    t.integer  "section_status",                    default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journey_patterns", ["objectid"], :name => "journey_patterns_objectid_key", :unique => true

  create_table "journey_patterns_stop_points", id: false, force: true do |t|
    t.integer "journey_pattern_id", limit: 8
    t.integer "stop_point_id",      limit: 8
  end

  add_index "journey_patterns_stop_points", ["journey_pattern_id"], :name => "index_journey_pattern_id_on_journey_patterns_stop_points"

  create_table "line_referential_memberships", force: true do |t|
    t.integer "organisation_id",     limit: 8
    t.integer "line_referential_id", limit: 8
    t.boolean "owner"
  end

  create_table "line_referential_sync_messages", force: true do |t|
    t.integer  "criticity"
    t.string   "message_key"
    t.hstore   "message_attributs"
    t.integer  "line_referential_sync_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "line_referential_sync_messages", ["line_referential_sync_id"], :name => "line_referential_sync_id"

  create_table "line_referential_syncs", force: true do |t|
    t.integer  "line_referential_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string   "status"
  end

  add_index "line_referential_syncs", ["line_referential_id"], :name => "index_line_referential_syncs_on_line_referential_id"

  create_table "line_referentials", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sync_interval", default: 1
  end

  create_table "lines", force: true do |t|
    t.integer  "network_id",                      limit: 8
    t.integer  "company_id",                      limit: 8
    t.string   "objectid",                                                  null: false
    t.integer  "object_version",                  limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "number"
    t.string   "published_name"
    t.string   "transport_mode"
    t.string   "registration_number"
    t.string   "comment"
    t.boolean  "mobility_restricted_suitability"
    t.integer  "int_user_needs"
    t.boolean  "flexible_service"
    t.string   "url"
    t.string   "color",                           limit: 6
    t.string   "text_color",                      limit: 6
    t.string   "stable_id"
    t.integer  "line_referential_id",             limit: 8
    t.boolean  "deactivated",                               default: false
    t.text     "import_xml"
    t.string   "transport_submode"
    t.integer  "secondary_company_ids",           limit: 8,                              array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lines", ["line_referential_id"], :name => "index_lines_on_line_referential_id"
  add_index "lines", ["objectid"], :name => "lines_objectid_key", :unique => true
  add_index "lines", ["registration_number"], :name => "lines_registration_number_key"
  add_index "lines", ["secondary_company_ids"], :name => "index_lines_on_secondary_company_ids"

  create_table "networks", force: true do |t|
    t.string   "objectid",                      null: false
    t.integer  "object_version",      limit: 8
    t.string   "creator_id"
    t.date     "version_date"
    t.string   "description"
    t.string   "name"
    t.string   "registration_number"
    t.string   "source_name"
    t.string   "source_type"
    t.string   "source_identifier"
    t.string   "comment"
    t.text     "import_xml"
    t.integer  "line_referential_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "networks", ["line_referential_id"], :name => "index_networks_on_line_referential_id"
  add_index "networks", ["objectid"], :name => "networks_objectid_key", :unique => true
  add_index "networks", ["registration_number"], :name => "networks_registration_number_key"

  create_table "organisations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "data_format",    default: "neptune"
    t.string   "code"
    t.datetime "synced_at"
    t.hstore   "sso_attributes"
  end

  add_index "organisations", ["code"], :name => "index_organisations_on_code", :unique => true

  create_table "pt_links", force: true do |t|
    t.integer  "start_of_link_id", limit: 8
    t.integer  "end_of_link_id",   limit: 8
    t.integer  "route_id",         limit: 8
    t.string   "objectid",                                            null: false
    t.integer  "object_version",   limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.decimal  "link_distance",              precision: 19, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pt_links", ["objectid"], :name => "pt_links_objectid_key", :unique => true

  create_table "referential_clonings", force: true do |t|
    t.string   "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "source_referential_id", limit: 8
    t.integer  "target_referential_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "referential_clonings", ["source_referential_id"], :name => "index_referential_clonings_on_source_referential_id"
  add_index "referential_clonings", ["target_referential_id"], :name => "index_referential_clonings_on_target_referential_id"

  create_table "referential_metadata", force: true do |t|
    t.integer   "referential_id",        limit: 8
    t.integer   "line_ids",              limit: 8, array: true
    t.integer   "referential_source_id", limit: 8
    t.datetime  "created_at"
    t.datetime  "updated_at"
    t.daterange "periodes",                        array: true
  end

  add_index "referential_metadata", ["line_ids"], :name => "index_referential_metadata_on_line_ids"
  add_index "referential_metadata", ["referential_id"], :name => "index_referential_metadata_on_referential_id"
  add_index "referential_metadata", ["referential_source_id"], :name => "index_referential_metadata_on_referential_source_id"

  create_table "referentials", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prefix"
    t.string   "projection_type"
    t.string   "time_zone"
    t.string   "bounds"
    t.integer  "organisation_id",          limit: 8
    t.text     "geographical_bounds"
    t.integer  "user_id",                  limit: 8
    t.string   "user_name"
    t.string   "data_format"
    t.integer  "line_referential_id",      limit: 8
    t.integer  "stop_area_referential_id", limit: 8
    t.integer  "workbench_id",             limit: 8
    t.datetime "archived_at"
    t.integer  "created_from_id",          limit: 8
    t.boolean  "ready",                              default: false
  end

  add_index "referentials", ["created_from_id"], :name => "index_referentials_on_created_from_id"

  create_table "route_sections", force: true do |t|
    t.integer  "departure_id",       limit: 8
    t.integer  "arrival_id",         limit: 8
    t.string   "objectid",                                                       null: false
    t.integer  "object_version",     limit: 8
    t.string   "creator_id"
    t.float    "distance"
    t.boolean  "no_processing"
    t.spatial  "input_geometry",     limit: {:srid=>4326, :type=>"line_string"}
    t.spatial  "processed_geometry", limit: {:srid=>4326, :type=>"line_string"}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "routes", force: true do |t|
    t.integer  "line_id",           limit: 8
    t.string   "objectid",                    null: false
    t.integer  "object_version",    limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.integer  "opposite_route_id", limit: 8
    t.string   "published_name"
    t.string   "number"
    t.string   "direction"
    t.string   "wayback"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "routes", ["objectid"], :name => "routes_objectid_key", :unique => true

  create_table "routing_constraint_zones", force: true do |t|
    t.string   "name"
    t.integer  "stop_area_ids",                         array: true
    t.integer  "line_id",        limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "objectid",                 null: false
    t.integer  "object_version", limit: 8
    t.string   "creator_id"
  end

  add_index "routing_constraint_zones", ["line_id"], :name => "index_routing_constraint_zones_on_line_id"

  create_table "routing_constraints_lines", id: false, force: true do |t|
    t.integer "stop_area_id", limit: 8
    t.integer "line_id",      limit: 8
  end

  create_table "rule_parameter_sets", force: true do |t|
    t.text     "parameters"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organisation_id", limit: 8
  end

  create_table "stop_area_referential_memberships", force: true do |t|
    t.integer "organisation_id",          limit: 8
    t.integer "stop_area_referential_id", limit: 8
    t.boolean "owner"
  end

  create_table "stop_area_referential_sync_messages", force: true do |t|
    t.integer  "criticity"
    t.string   "message_key"
    t.hstore   "message_attributs"
    t.integer  "stop_area_referential_sync_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stop_area_referential_sync_messages", ["stop_area_referential_sync_id"], :name => "stop_area_referential_sync_id"

  create_table "stop_area_referential_syncs", force: true do |t|
    t.integer  "stop_area_referential_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "ended_at"
    t.datetime "started_at"
    t.string   "status"
  end

  add_index "stop_area_referential_syncs", ["stop_area_referential_id"], :name => "index_stop_area_referential_syncs_on_stop_area_referential_id"

  create_table "stop_area_referentials", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stop_areas", force: true do |t|
    t.integer  "parent_id",                       limit: 8
    t.string   "objectid",                                                            null: false
    t.integer  "object_version",                  limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.string   "comment"
    t.string   "area_type"
    t.string   "registration_number"
    t.string   "nearest_topic_name"
    t.integer  "fare_code"
    t.decimal  "longitude",                                 precision: 19, scale: 16
    t.decimal  "latitude",                                  precision: 19, scale: 16
    t.string   "long_lat_type"
    t.string   "country_code"
    t.string   "street_name"
    t.boolean  "mobility_restricted_suitability"
    t.boolean  "stairs_availability"
    t.boolean  "lift_availability"
    t.integer  "int_user_needs"
    t.string   "zip_code"
    t.string   "city_name"
    t.string   "url"
    t.string   "time_zone"
    t.integer  "stop_area_referential_id",        limit: 8
    t.string   "status"
    t.text     "import_xml"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stop_areas", ["name"], :name => "index_stop_areas_on_name"
  add_index "stop_areas", ["objectid"], :name => "stop_areas_objectid_key", :unique => true
  add_index "stop_areas", ["parent_id"], :name => "index_stop_areas_on_parent_id"
  add_index "stop_areas", ["stop_area_referential_id"], :name => "index_stop_areas_on_stop_area_referential_id"

  create_table "stop_areas_stop_areas", id: false, force: true do |t|
    t.integer "child_id",  limit: 8
    t.integer "parent_id", limit: 8
  end

  create_table "stop_points", force: true do |t|
    t.integer  "route_id",       limit: 8
    t.integer  "stop_area_id",   limit: 8
    t.string   "objectid",                 null: false
    t.integer  "object_version", limit: 8
    t.string   "creator_id"
    t.integer  "position"
    t.string   "for_boarding"
    t.string   "for_alighting"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stop_points", ["objectid"], :name => "stop_points_objectid_key", :unique => true

  create_table "taggings", force: true do |t|
    t.integer  "tag_id",        limit: 8
    t.integer  "taggable_id",   limit: 8
    t.string   "taggable_type"
    t.integer  "tagger_id",     limit: 8
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "time_table_dates", force: true do |t|
    t.integer "time_table_id", limit: 8, null: false
    t.date    "date"
    t.integer "position",                null: false
    t.boolean "in_out"
  end

  add_index "time_table_dates", ["time_table_id"], :name => "index_time_table_dates_on_time_table_id"

  create_table "time_table_periods", force: true do |t|
    t.integer "time_table_id", limit: 8, null: false
    t.date    "period_start"
    t.date    "period_end"
    t.integer "position",                null: false
  end

  add_index "time_table_periods", ["time_table_id"], :name => "index_time_table_periods_on_time_table_id"

  create_table "time_tables", force: true do |t|
    t.string   "objectid",                             null: false
    t.integer  "object_version", limit: 8, default: 1
    t.string   "creator_id"
    t.string   "version"
    t.string   "comment"
    t.integer  "int_day_types",            default: 0
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "calendar_id",    limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "time_tables", ["calendar_id"], :name => "index_time_tables_on_calendar_id"
  add_index "time_tables", ["objectid"], :name => "time_tables_objectid_key", :unique => true

  create_table "time_tables_vehicle_journeys", id: false, force: true do |t|
    t.integer "time_table_id",      limit: 8
    t.integer "vehicle_journey_id", limit: 8
  end

  add_index "time_tables_vehicle_journeys", ["time_table_id"], :name => "index_time_tables_vehicle_journeys_on_time_table_id"
  add_index "time_tables_vehicle_journeys", ["vehicle_journey_id"], :name => "index_time_tables_vehicle_journeys_on_vehicle_journey_id"

  create_table "timebands", force: true do |t|
    t.string   "objectid",                 null: false
    t.integer  "object_version", limit: 8
    t.string   "creator_id"
    t.string   "name"
    t.time     "start_time",               null: false
    t.time     "end_time",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "translations", force: true do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "value"
    t.text     "interpolations"
    t.boolean  "is_proc",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                            default: "", null: false
    t.string   "encrypted_password",               default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                    default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organisation_id",        limit: 8
    t.string   "name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                  default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.string   "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id",          limit: 8
    t.string   "invited_by_type"
    t.datetime "invitation_created_at"
    t.string   "username"
    t.datetime "synced_at"
    t.string   "permissions",                                                array: true
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "vehicle_journey_at_stops", force: true do |t|
    t.integer "vehicle_journey_id",             limit: 8
    t.integer "stop_point_id",                  limit: 8
    t.string  "connecting_service_id"
    t.string  "boarding_alighting_possibility"
    t.time    "arrival_time"
    t.time    "departure_time"
    t.string  "for_boarding"
    t.string  "for_alighting"
  end

  add_index "vehicle_journey_at_stops", ["stop_point_id"], :name => "index_vehicle_journey_at_stops_on_stop_pointid"
  add_index "vehicle_journey_at_stops", ["vehicle_journey_id"], :name => "index_vehicle_journey_at_stops_on_vehicle_journey_id"

  create_table "vehicle_journeys", force: true do |t|
    t.integer  "route_id",                        limit: 8
    t.integer  "journey_pattern_id",              limit: 8
    t.integer  "company_id",                      limit: 8
    t.string   "objectid",                                              null: false
    t.integer  "object_version",                  limit: 8
    t.string   "creator_id"
    t.string   "comment"
    t.string   "status_value"
    t.string   "transport_mode"
    t.string   "published_journey_name"
    t.string   "published_journey_identifier"
    t.string   "facility"
    t.string   "vehicle_type_identifier"
    t.integer  "number",                          limit: 8
    t.boolean  "mobility_restricted_suitability"
    t.boolean  "flexible_service"
    t.integer  "journey_category",                          default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_journeys", ["objectid"], :name => "vehicle_journeys_objectid_key", :unique => true
  add_index "vehicle_journeys", ["route_id"], :name => "index_vehicle_journeys_on_route_id"

  create_table "workbenches", force: true do |t|
    t.string   "name"
    t.integer  "organisation_id",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "line_referential_id",      limit: 8
    t.integer  "stop_area_referential_id", limit: 8
  end

  add_index "workbenches", ["line_referential_id"], :name => "index_workbenches_on_line_referential_id"
  add_index "workbenches", ["organisation_id"], :name => "index_workbenches_on_organisation_id"
  add_index "workbenches", ["stop_area_referential_id"], :name => "index_workbenches_on_stop_area_referential_id"

  Foreigner.load
  add_foreign_key "group_of_lines_lines", "group_of_lines", name: "groupofline_group_fkey", dependent: :delete

  add_foreign_key "journey_frequencies", "timebands", name: "journey_frequencies_timeband_id_fk", dependent: :nullify
  add_foreign_key "journey_frequencies", "vehicle_journeys", name: "journey_frequencies_vehicle_journey_id_fk", dependent: :nullify

  add_foreign_key "journey_pattern_sections", "journey_patterns", name: "journey_pattern_sections_journey_pattern_id_fk", dependent: :delete
  add_foreign_key "journey_pattern_sections", "route_sections", name: "journey_pattern_sections_route_section_id_fk", dependent: :delete

  add_foreign_key "journey_patterns", "routes", name: "jp_route_fkey", dependent: :delete
  add_foreign_key "journey_patterns", "stop_points", name: "arrival_point_fkey", column: "arrival_stop_point_id", dependent: :nullify
  add_foreign_key "journey_patterns", "stop_points", name: "departure_point_fkey", column: "departure_stop_point_id", dependent: :nullify

  add_foreign_key "journey_patterns_stop_points", "journey_patterns", name: "jpsp_jp_fkey", dependent: :delete
  add_foreign_key "journey_patterns_stop_points", "stop_points", name: "jpsp_stoppoint_fkey", dependent: :delete

  add_foreign_key "routes", "routes", name: "route_opposite_route_fkey", column: "opposite_route_id", dependent: :nullify

  add_foreign_key "stop_areas", "stop_areas", name: "area_parent_fkey", column: "parent_id", dependent: :nullify

  add_foreign_key "stop_areas_stop_areas", "stop_areas", name: "stoparea_child_fkey", column: "child_id", dependent: :delete
  add_foreign_key "stop_areas_stop_areas", "stop_areas", name: "stoparea_parent_fkey", column: "parent_id", dependent: :delete

  add_foreign_key "stop_points", "routes", name: "stoppoint_route_fkey", dependent: :delete

  add_foreign_key "time_table_dates", "time_tables", name: "tm_date_fkey", dependent: :delete

  add_foreign_key "time_table_periods", "time_tables", name: "tm_period_fkey", dependent: :delete

  add_foreign_key "time_tables_vehicle_journeys", "time_tables", name: "vjtm_tm_fkey", dependent: :delete
  add_foreign_key "time_tables_vehicle_journeys", "vehicle_journeys", name: "vjtm_vj_fkey", dependent: :delete

  add_foreign_key "vehicle_journey_at_stops", "stop_points", name: "vjas_sp_fkey", dependent: :delete
  add_foreign_key "vehicle_journey_at_stops", "vehicle_journeys", name: "vjas_vj_fkey", dependent: :delete

  add_foreign_key "vehicle_journeys", "journey_patterns", name: "vj_jp_fkey", dependent: :delete
  add_foreign_key "vehicle_journeys", "routes", name: "vj_route_fkey", dependent: :delete

end
