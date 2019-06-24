class FixIds < ActiveRecord::Migration[5.2]
  def up
    %w(access_links access_points aggregates api_keys calendars clean_up_results clean_ups companies compliance_check_blocks compliance_check_messages compliance_check_resources compliance_check_sets compliance_checks compliance_control_blocks compliance_control_sets compliance_controls connection_links custom_fields delayed_jobs delayed_workers destination_reports destinations exports facilities footnotes group_of_lines import_messages import_resources imports journey_patterns line_referential_memberships line_referential_sync_messages line_referential_syncs line_referentials lines merges networks organisations pt_links publication_api_keys publication_api_sources publication_apis publication_setups publications purchase_windows referential_clonings referential_metadata referential_suites referentials routes routing_constraint_zones simple_interfaces stat_journey_pattern_courses_by_dates stop_area_providers stop_area_providers_areas stop_area_referential_memberships stop_area_referential_sync_messages stop_area_referential_syncs stop_area_referentials stop_area_routing_constraints stop_areas stop_points taggings tags time_tables users vehicle_journey_at_stops vehicle_journeys workbenches workgroups).each do |t|
      change_column t, :id, :bigint
    end

    on_public_schema_only do
      %w{cross_referential_index_entries notifications notification_rules}.each do |t|
        change_column t, :id, :bigint
      end
    end

    change_column :connection_links, :stop_area_referential_id, :bigint
    change_column :stop_areas, :referent_id, :bigint
  end

  def down
    %w(access_links access_points aggregates api_keys calendars clean_up_results clean_ups companies compliance_check_blocks compliance_check_messages compliance_check_resources compliance_check_sets compliance_checks compliance_control_blocks compliance_control_sets compliance_controls connection_links custom_fields delayed_jobs delayed_workers destination_reports destinations exports facilities footnotes group_of_lines import_messages import_resources imports journey_patterns line_referential_memberships line_referential_sync_messages line_referential_syncs line_referentials lines merges networks organisations pt_links publication_api_keys publication_api_sources publication_apis publication_setups publications purchase_windows referential_clonings referential_metadata referential_suites referentials routes routing_constraint_zones simple_interfaces stat_journey_pattern_courses_by_dates stop_area_providers stop_area_providers_areas stop_area_referential_memberships stop_area_referential_sync_messages stop_area_referential_syncs stop_area_referentials stop_area_routing_constraints stop_areas stop_points taggings tags time_tables users vehicle_journey_at_stops vehicle_journeys workbenches workgroups).each do |t|
      change_column t, :id, :int
    end

    on_public_schema_only do
      %w{cross_referential_index_entries notifications notification_rules}.each do |t|
        change_column t, :id, :int
      end
    end


    change_column :connection_links, :stop_area_referential_id, :int
    change_column :stop_areas, :referent_id, :int
  end
end
