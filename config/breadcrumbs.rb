crumb :root do
  link image_pack_tag('static/logo-chouette-2020-vertical-white.png', class: "chouette-little-logo").html_safe, root_path
end

crumb :workbench do |workbench|
  link workbench.name.capitalize, workbench_path(workbench)
  parent :workgroup, workbench.workgroup
end

crumb :workgroups do |workgroup|
  link Workgroup.t, workgroups_path()
end

crumb :workgroup do |workgroup, display_parent|
  link workgroup.name, workgroup_path(workgroup)
  parent :workgroups if display_parent
end

crumb :add_workbench do |workgroup|
  link I18n.t('workbenches.new.title'), '#'
  parent :workgroup, workgroup
end

crumb :workbench_confirmation do
  link I18n.t('workbench_confirmation.new.title'), workbench_confirmation_path
  parent :workgroups
end

crumb :workbench_configure do |workbench|
  link I18n.t('workbenches.edit.title'), edit_workbench_path(workbench)
  parent :workbench, workbench
end

crumb :workbench_output do |workbench|
  link I18n.t('workbench_outputs.show.title'), workbench_output_path(workbench)
  parent :workbench, mutual_workbench(workbench)
end

crumb :workgroup_output do |workgroup|
  link 'layouts.navbar.workbench_outputs.workgroup'.t, workgroup_output_path(workgroup)
end

crumb :merges do |workbench|
  link I18n.t('merges.index.title'), workbench_output_path(workbench)
  parent :workbench, workbench
end

crumb :macro_lists do |workbench|
  link I18n.t('macro_lists.index.title'), workbench_macro_lists_path(workbench)
  parent :workbench, workbench
end

crumb :macro_list do |workbench, macro_list|
  link breadcrumb_name(macro_list), workbench_macro_list_path(workbench, macro_list)
  parent :macro_lists, workbench
end

crumb :new_macro_list do |workbench|
  link I18n.t('macro_lists.new.title')
  parent :macro_lists, workbench
end

crumb :point_of_interests do |workbench|
  link I18n.t('point_of_interests.index.title'), workbench_shape_referential_point_of_interests_path(workbench)
  parent :workbench, workbench
end

crumb :point_of_interest do |workbench, point_of_interest|
  link breadcrumb_name(point_of_interest), workbench_shape_referential_point_of_interest_path(workbench, point_of_interest)
  parent :point_of_interests, workbench
end

crumb :new_point_of_interest do |workbench|
  link I18n.t('point_of_interests.new.title')
  parent :point_of_interests, workbench
end

crumb :processing_rules do |workbench|
  link I18n.t('processing_rules.index.title'), workbench_processing_rules_path(workbench)
  parent :workbench, workbench
end

crumb :processing_rule do |workbench, processing_rule|
  link breadcrumb_name(processing_rule), workbench_processing_rule_path(workbench, processing_rule)
  parent :processing_rules, workbench
end

crumb :new_processing_rule do |workbench|
  link I18n.t('processing_rules.new.title')
  parent :processing_rules, workbench
end

crumb :point_of_interest_categories do |workbench|
  link I18n.t('point_of_interest_categories.index.title'), workbench_shape_referential_point_of_interest_categories_path(workbench)
  parent :workbench, workbench
end

crumb :point_of_interest_category do |workbench, point_of_interest_category|
  link breadcrumb_name(point_of_interest_category), workbench_shape_referential_point_of_interest_category_path(workbench, point_of_interest_category)
  parent :point_of_interest_categories, workbench
end

crumb :new_point_of_interest_category do |workbench|
  link I18n.t('point_of_interest_categories.new.title')
  parent :point_of_interest_categories, workbench
end

crumb :document_types do |workgroup|
  link I18n.t('document_types.index.title'), workgroup_document_types_path(workgroup)
  parent :workgroup, workgroup
end

crumb :document_type do |workgroup, document_type|
  link breadcrumb_name(document_type), workgroup_document_type_path(workgroup, document_type)
  parent :document_types, workgroup
end

crumb :new_document_type do |workgroup|
  link I18n.t('document_types.new.title')
  parent :document_types, workgroup
end

crumb :sources do |workbench|
  link I18n.t('sources.index.title'), workbench_sources_path(workbench)
  parent :workbench, workbench
end

crumb :source do |workbench, source|
  link breadcrumb_name(source), workbench_source_path(workbench, source)
  parent :sources, workbench
end

crumb :new_source do |workbench|
  link I18n.t('sources.new.title')
  parent :sources, workbench
end

crumb :macro_list_runs do |workbench|
  link I18n.t('macro_list_run.index.title'), workbench_macro_list_runs_path(workbench)
  parent :workbench, workbench
end

crumb :macro_list_run do |workbench, macro_list_run|
  link breadcrumb_name(macro_list_run), workbench_macro_list_run_path(workbench, macro_list_run)
  parent :macro_list_runs, workbench
end

crumb :new_macro_list_run do |workbench|
  link I18n.t('macro_list_run.new.title')
  parent :macro_list_runs, workbench
end

crumb :control_lists do |workbench|
  link I18n.t('control/lists.index.title'), workbench_control_lists_path(workbench)
  parent :workbench, workbench
end

crumb :control_list do |workbench, control_list|
  link breadcrumb_name(control_list), workbench_control_list_path(workbench, control_list)
  parent :control_lists, workbench
end

crumb :new_control_list do |workbench|
  link I18n.t('control/lists.new.title')
  parent :control_lists, workbench
end

crumb :control_list_runs do |workbench|
  link I18n.t('control/list/runs.index.title'), workbench_control_list_runs_path(workbench)
  parent :workbench, workbench
end

crumb :control_list_run do |workbench, control_list_run|
  link breadcrumb_name(control_list_run), workbench_control_list_run_path(workbench, control_list_run)
  parent :control_list_runs, workbench
end

crumb :new_control_list_run do |workbench|
  link I18n.t('control/list/runs.new.title')
  parent :control_list_runs, workbench
end

crumb :merge do |merge|
  link breadcrumb_name(merge), workbench_merge_path(merge.workbench, merge)
  parent :merges, merge.workbench
end

crumb :publications_menu do |workgroup|
  link 'layouts.navbar.publications.subtitle'.t
  parent workgroup
end

crumb :publication_apis do |workgroup|
  link PublicationApi.t, workgroup_publication_apis_path(workgroup)
  parent :publications_menu, workgroup
end

crumb :publication_api do |publication_api|
  link publication_api.name, [publication_api.workgroup, publication_api]
  parent :publication_apis, publication_api.workgroup
end

crumb :new_publication_api_key do |publication_api|
  link 'publication_api_keys.actions.new'.t
  parent publication_api
end

crumb :publication_api_key do |publication_api_key|
  link publication_api_key.name
  parent publication_api_key.publication_api
end

crumb :new_publication_api do |workgroup|
  link 'publication_apis.actions.new'.t
  parent :publication_apis, workgroup
end

crumb :publication_setups do |workgroup|
  link PublicationSetup.t, workgroup_publication_setups_path(workgroup)
  parent :publications_menu, workgroup
end

crumb :publication do |publication|
  link publication.pretty_date, [publication.publication_setup.workgroup, publication.publication_setup, publication]
  parent publication.publication_setup
end

crumb :publication_setup do |publication_setup|
  link publication_setup.name, [publication_setup.workgroup, publication_setup]
  parent :publication_setups, publication_setup.workgroup
end

crumb :new_publication_setup do |workgroup|
  link 'publication_setups.actions.new'.t
  parent :publication_setups, workgroup
end

crumb :aggregates do |workgroup|
  link 'layouts.navbar.workbench_outputs.workgroup'.t, workgroup_output_path(workgroup)
end

crumb :aggregate do |aggregate|
  link breadcrumb_name(aggregate), workgroup_aggregate_path(aggregate.workgroup, aggregate)
  parent :aggregates, aggregate.workgroup
end

crumb :referential do |referential|
  link breadcrumb_name(referential), referential_path(referential)
  if referential.workbench
    parent :workbench, mutual_workbench(referential.workbench || referential.workgroup.workbenches.last)
  else
    parent :workgroup_output, referential.workgroup
  end
end

crumb :referentials do |referential|
  link I18n.t('referentials.index.title'), workbench_path(current_workbench)
  parent :workbench, mutual_workbench(current_workbench)
end

crumb :referential_companies do |referential|
  link I18n.t('companies.index.title'), referential_companies_path(referential)
  parent :referential, referential
end

crumb :referential_company do |referential, company|
  link breadcrumb_name(company), referential_company_path(referential, company)
  parent :referential_companies, referential
end

crumb :referential_networks do |referential|
  link I18n.t('networks.index.title'), referential_networks_path
  parent :referential, referential
end

crumb :referential_network do |referential, network|
  link  breadcrumb_name(network), referential_network_path(referential, network)
  parent :referential_networks, referential
end

crumb :referential_vehicle_journeys do |referential|
  link I18n.t('referential_vehicle_journeys.index.title'), referential_vehicle_journeys_path(referential)
  parent :referential, referential
end

crumb :time_tables do |referential|
  link I18n.t('time_tables.index.title'), referential_time_tables_path(referential)
  parent :referential, referential
end

crumb :time_table do |referential, time_table|
  link breadcrumb_name(time_table, 'comment'), referential_time_table_path(referential, time_table)
  parent :time_tables, referential
end

crumb :compliance_check_sets do |ccset_parent|
  if ccset_parent.is_a?(Workbench)
    link I18n.t('compliance_check_sets.index.title'), workbench_compliance_check_sets_path(ccset_parent)
    parent :workbench, ccset_parent
  else
    link I18n.t('compliance_check_sets.index.title'), workgroup_compliance_check_sets_path(ccset_parent)
    parent :imports_parent, ccset_parent
  end
end

crumb :compliance_check_set do |ccset_parent, compliance_check_set|
  link breadcrumb_name(compliance_check_set), [ccset_parent, compliance_check_set]
  parent :compliance_check_sets, ccset_parent
end

crumb :compliance_check do |cc_set_parent, compliance_check|
  link breadcrumb_name(compliance_check), [cc_set_parent, compliance_check.compliance_check_set, compliance_check]
  parent :compliance_check_set_executed, cc_set_parent, compliance_check.compliance_check_set
end

crumb :compliance_check_set_executed do |cc_set_parent, compliance_check_set|
  link I18n.t('compliance_check_sets.executed.title', name: compliance_check_set.name), [:executed, cc_set_parent, compliance_check_set]
  parent :compliance_check_sets, cc_set_parent
end

crumb :imports_parent do |imports_parent|
  if imports_parent.is_a? Workgroup
    link Workgroup.ts, [imports_parent]
  else
    link imports_parent.name, [imports_parent]
  end
end

crumb :imports do |imports_parent|
  link I18n.t('imports.index.title'), [imports_parent, :imports]
  parent :imports_parent, imports_parent
end

crumb :import do |imports_parent, import|
  link breadcrumb_name(import), [imports_parent, import]
  parent :imports, imports_parent
end

crumb :exports do |export_parent|
  link I18n.t('exports.index.title'),[export_parent, :exports]
  parent export_parent
end

crumb :export do |export_parent, export|
  link breadcrumb_name(export), [export_parent, export]
  parent :exports, export_parent
end

crumb :netex_import do |imports_parent, netex_import|
  link breadcrumb_name(netex_import), [imports_parent, netex_import]
  parent :import, imports_parent, netex_import.parent
end

crumb :gtfs_import do |imports_parent, gtfs_import|
  link breadcrumb_name(gtfs_import), [imports_parent, gtfs_import]
  parent :import, imports_parent, gtfs_import.parent
end

crumb :shapefile_import do |imports_parent, shapefile_import|
  link breadcrumb_name(shapefile_import), [imports_parent, shapefile_import]
  parent :import, imports_parent, shapefile_import.parent
end

crumb :import_resources do |import, import_resources|
  link I18n.t('import.resources.index.title'), workbench_import_import_resources_path(import.workbench, import.parent)
  parent :import, import.workbench, import.parent
end

crumb :import_resource do |import_resource|
  link I18n.t('import.resources.index.title'), workbench_import_import_resource_path(import_resource.root_import.workbench, import_resource.root_import, import_resource)
  parent :import, import_resource.root_import.workbench, import_resource.root_import
end

crumb :user do |user|
  link user.name, organisation_user_path(user)
  parent user.organisation
end

crumb :edit_user do |user|
  link 'users.actions.edit'.t
  parent user
end

crumb :new_invitation do |organisation|
  link 'actions.invite_user'.t
  parent organisation
end

crumb :organisation do |organisation|
  link breadcrumb_name(organisation), organisation_path()
end

crumb :compliance_control_sets do
  link I18n.t('compliance_control_sets.index.title'), compliance_control_sets_path
end

crumb :compliance_control_set do |compliance_control_set|
  link breadcrumb_name(compliance_control_set), compliance_control_set_path(compliance_control_set)
  parent :compliance_control_sets
end

crumb :compliance_control do |compliance_control|
  link breadcrumb_name(compliance_control), compliance_control_set_compliance_control_path(compliance_control.compliance_control_set, compliance_control)
  parent :compliance_control_set, compliance_control.compliance_control_set
end

crumb :stop_area_referential do |workbench|
  link I18n.t('stop_area_referentials.show.title'), workbench_stop_area_referential_path(workbench)
  parent :workbench, workbench
end

crumb :stop_areas do |workbench|
  link I18n.t('stop_areas.index.title'), workbench_stop_area_referential_stop_areas_path(workbench)
  parent :stop_area_referential, workbench
end

crumb :entrances do |workbench|
  link I18n.t('entrances.index.title'), workbench_stop_area_referential_entrances_path(workbench)
  parent :stop_area_referential, workbench
end

crumb :entrance do |workbench, entrance|
  link breadcrumb_name(entrance), workbench_stop_area_referential_entrance_path(workbench, entrance)
  parent :entrances, workbench
end

crumb :connection_links do |workbench|
  link I18n.t('connection_links.index.title'), workbench_stop_area_referential_connection_links_path(workbench)
  parent :stop_area_referential, workbench
end

crumb :stop_area_providers do |workbench|
  link StopAreaProvider.t, workbench_stop_area_referential_stop_area_providers_path(workbench)
  parent :stop_area_referential, workbench
end

crumb :stop_area_provider do |workbench, stop_area_provider|
  link stop_area_provider.name, workbench_stop_area_referential_stop_area_provider_path(workbench, stop_area_provider)
  parent :stop_area_providers, workbench
end

crumb :stop_area_routing_constraints do |workbench|
  link StopAreaRoutingConstraint.t, workbench_stop_area_referential_stop_area_routing_constraints_path(workbench)
  parent :stop_area_referential, workbench
end

crumb :stop_area_routing_constraint do |workbench, stop_area_routing_constraint|
  link stop_area_routing_constraint.name, workbench_stop_area_referential_stop_area_routing_constraint_path(workbench, stop_area_routing_constraint)
  parent :stop_area_routing_constraints, workbench
end

crumb :stop_area do |workbench, stop_area|
  link breadcrumb_name(stop_area), workbench_stop_area_referential_stop_area_path(workbench, stop_area)
  parent :stop_areas, workbench
end

crumb :connection_link do |workbench, connection_link|
  link breadcrumb_name(connection_link), workbench_stop_area_referential_connection_link_path(workbench, connection_link)
  parent :connection_links, workbench
end

crumb :line_referential do |workbench|
  link I18n.t('line_referentials.show.title'), workbench_line_referential_path(workbench)
  parent :workbench, workbench
end

crumb :companies do |workbench|
  link I18n.t('companies.index.title'), workbench_line_referential_companies_path(workbench)
  parent :line_referential, workbench
end

crumb :company do |workbench, company|
  link breadcrumb_name(company), workbench_line_referential_company_path(workbench, company)
  parent :companies, workbench
end

crumb :networks do |workbench|
  link I18n.t('networks.index.title'), workbench_line_referential_networks_path(workbench)
  parent :line_referential, workbench
end

crumb :network do |workbench, network|
  link breadcrumb_name(network), workbench_line_referential_network_path(workbench, network)
  parent :networks, workbench
end

crumb :line_notices do |workbench, line|
  link I18n.t('line_notices.index.title'), workbench_line_referential_line_notices_path(workbench)
  if line
    parent :line, workbench, line
  else
    parent :line_referential, workbench
  end
end

crumb :line_notice do |workbench, line_notice|
  link breadcrumb_name(line_notice), workbench_line_referential_line_notice_path(workbench, line_notice)
  parent :line_notices, workbench
end

crumb :attach_notice do |line_referential, line|
  link 'line_notices.actions.attach'.t
  parent line, line_referential
end

crumb :line_providers do |workbench|
  link LineProvider.t, workbench_line_referential_line_providers_path(workbench)
  parent :line_referential, workbench
end

crumb :new_line_provider do |workbench, line_provider|
  link I18n.t('line_providers.new.title')
  parent :line_providers, workbench
end

crumb :line_provider do |workbench, line_provider|
  link line_provider.short_name, workbench_line_referential_line_provider_path(workbench, line_provider)
  parent :line_providers, workbench
end

crumb :lines do |workbench|
  link I18n.t('lines.index.title'), workbench_line_referential_lines_path(workbench)
  parent :line_referential, workbench
end

crumb :line do |workbench, line|
  link breadcrumb_name(line), workbench_line_referential_line_path(workbench, line)
  parent :lines, workbench
end

crumb :line_routing_constraint_zones do |workbench|
  link I18n.t('line_routing_constraint_zones.index.title'), workbench_line_referential_line_routing_constraint_zones_path(workbench)
  parent :line_referential, workbench
end

crumb :line_routing_constraint_zone do |workbench, line_routing_constraint_zone|
  link line_routing_constraint_zone.name, workbench_line_referential_line_routing_constraint_zone_path(workbench, line_routing_constraint_zone)
  parent :line_routing_constraint_zones, workbench
end

crumb :new_line_routing_constraint_zone do |workbench|
  link I18n.t('line_routing_constraint_zones.new.title')
  parent :line_routing_constraint_zones, workbench
end

crumb :calendars do |workgroup|
  link I18n.t('calendars.index.title'), workgroup_calendars_path(workgroup)
end

crumb :calendar do |workgroup, calendar|
  link breadcrumb_name(calendar), workgroup_calendar_path(workgroup, calendar)
  parent :calendars, workgroup
end

crumb :referential_line do |referential, line|
  link breadcrumb_name(line), referential_line_path(referential, line)
  parent :referential, referential
end

crumb :footnotes do |referential, line|
  link I18n.t('footnotes.index.title'), referential_line_footnotes_path(referential, line)
  parent :referential_line, referential, line
end

crumb :routing_constraint_zones do |referential, line|
  link I18n.t('routing_constraint_zones.index.title'), referential_line_routing_constraint_zones_path(referential, line)
  parent :referential_line, referential, line
end

crumb :routing_constraint_zone do |referential, line, routing_constraint_zone|
  link breadcrumb_name(routing_constraint_zone), referential_line_routing_constraint_zone_path(referential, line, routing_constraint_zone)
  parent :routing_constraint_zones, referential, line
end

crumb :route do |referential, route|
  link I18n.t('routes.index.title', route: route.name), referential_line_route_path(referential, route.line, route)
  parent :referential_line, referential, route.line
end

crumb :journey_patterns do |referential, route|
  link I18n.t('journey_patterns.index.title', route: route.name), referential_line_route_journey_patterns_collection_path(referential, route.line, route)
  parent :route, referential, route
end

crumb :vehicle_journeys do |referential, route|
  link I18n.t('vehicle_journeys.index.title', route: route.name), referential_line_route_vehicle_journeys_path(referential, route.line, route)
  parent :route, referential, route
end

crumb :workgroup_aggregation_settings do |workgroup|
  link I18n.t('workgroups.edit_aggregate.title')
  parent workgroup
end

crumb :workgroup_edit_controls do |workgroup|
  link I18n.t('workgroups.edit_controls.title')
  parent workgroup
end

crumb :workgroup_edit_merge do |workgroup|
  link I18n.t('workgroups.edit_merge.title')
  parent workgroup
end

crumb :workgroup_transport_modes_settings do |workgroup|
  link I18n.t('workgroups.edit_transport_modes.title')
  parent workgroup
end

crumb :api_keys do |workbench|
  link I18n.t('api_keys.index.title'), workbench_api_keys_path(workbench)
  parent :workbench, workbench
end

crumb :notification_rules do |workbench|
  link I18n.t('notification_rules.index.title'), workbench_notification_rules_path(workbench)
  parent :workbench, workbench
end

crumb :notification_rule do |notification_rule|
  link notification_rule.name
  parent :notification_rules, notification_rule.workbench
end

crumb :shapes do |workbench|
  link I18n.t('shapes.index.title'), workbench_shape_referential_shapes_path(workbench)
  parent :workbench, workbench
end

crumb :shape do |workbench, shape|
  link breadcrumb_name(shape, (shape.name.present? ? :name : :uuid )), workbench_shape_referential_shape_path(workbench, shape)
  parent :shapes, workbench
end

crumb :code_spaces do |workgroup|
  link CodeSpace.model_name.human(count: 2), workgroup_code_spaces_path(workgroup)
  parent workgroup
end

crumb :code_space do |workgroup, code_space|
  link "#{CodeSpace.model_name.human} #{code_space.short_name}", workgroup_code_space_path(workgroup, code_space)
  parent :code_spaces, workgroup
end

crumb :new_code_space do |workgroup|
  link I18n.t('code_spaces.new.title')
  parent :code_spaces, workgroup
end

crumb :documents do |workbench|
  link I18n.t('documents.index.title'), workbench_documents_path(workbench)
  parent :workbench, workbench
end

crumb :document do |workbench, document|
  link breadcrumb_name(document), workbench_document_path(workbench, document)
  parent :documents, workbench
end

crumb :new_document do |workbench|
  link I18n.t('documents.new.title')
  parent :documents, workbench
end

crumb :document_memberships do |workbench, line|
  link I18n.t('documents.index.title'), workbench_line_referential_line_document_memberships_path(workbench, line)
  parent :line, workbench, line
end
