crumb :root do
  link I18n.t('layouts.home'), root_path
end

crumb :workbench do |workbench|
  link workbench.name, workbench_path(workbench)
end

crumb :workbench_output do |workbench|
  link I18n.t('workbench_outputs.show.title'), workbench_output_path(workbench)
  parent :workbench, workbench
end

crumb :merges do |workbench|
  link I18n.t('merges.index.title'), workbench_output_path(workbench)
  parent :workbench, workbench
end

crumb :merge do |merge|
  link breadcrumb_name(merge), workbench_merge_path(merge.workbench, merge)
  parent :merges, merge.workbench
end

crumb :referential do |referential|
  link breadcrumb_name(referential), referential_path(referential)
  parent :workbench, mutual_workbench(referential.workbench)
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

crumb :referential_group_of_lines do |referential|
  link I18n.t('group_of_lines.index.title'), referential_networks_path(referential)
  parent :referential, referential
end

crumb :referential_group_of_line do |referential, group_of_line|
  link  breadcrumb_name(group_of_line), referential_group_of_line_path(referential, group_of_line)
  parent :referential_group_of_lines, referential
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

crumb :timebands do |referential|
  link I18n.t('timebands.index.title'), referential_timebands_path(referential)
  parent :referential, referential
end

crumb :timeband do |referential, timeband|
  link breadcrumb_name(timeband), referential_timeband_path(referential, timeband)
  parent :timebands, referential
end

crumb :compliance_check_sets do |workbench|
  link I18n.t('compliance_check_sets.index.title'), workbench_compliance_check_sets_path(workbench)
  parent :workbench, workbench
end

crumb :compliance_check_set do |workbench, compliance_check_set|
  link breadcrumb_name(compliance_check_set), workbench_compliance_check_set_path(workbench, compliance_check_set)
  parent :compliance_check_sets, workbench
end

crumb :compliance_check_set_executed do |workbench, compliance_check_set|
  link I18n.t('compliance_check_sets.executed.title', name: compliance_check_set.name), executed_workbench_compliance_check_set_path(workbench, compliance_check_set)
  parent :compliance_check_sets, workbench
end

crumb :imports do |workbench|
  link I18n.t('imports.index.title'), workbench_imports_path(workbench)
  parent :workbench, workbench
end

crumb :import do |workbench, import|
  link breadcrumb_name(import), workbench_import_path(workbench, import)
  parent :imports, workbench
end

crumb :import_resources do |import, import_resources|
  link I18n.t('import_resources.index.title'), workbench_import_import_resources_path(import.workbench, import.parent)
  parent :import, import.workbench, import.parent
end

crumb :organisation do |organisation|
  link breadcrumb_name(organisation), organisation_path(organisation)
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

crumb :stop_area_referential do |stop_area_referential|
  link I18n.t('stop_area_referentials.show.title'), stop_area_referential_path(stop_area_referential)
end

crumb :stop_areas do |stop_area_referential|
  link I18n.t('stop_areas.index.title'), stop_area_referential_stop_areas_path(stop_area_referential)
  parent :stop_area_referential, stop_area_referential
end

crumb :stop_area do |stop_area_referential, stop_area|
  link breadcrumb_name(stop_area), stop_area_referential_stop_area_path(stop_area_referential, stop_area)
  parent :stop_areas, stop_area_referential
end

crumb :line_referential do |line_referential|
  link I18n.t('line_referentials.show.title'), line_referential_path(line_referential)
end

crumb :companies do |line_referential|
  link I18n.t('companies.index.title'), line_referential_companies_path(line_referential)
  parent :line_referential, line_referential
end

crumb :company do |company|
  link breadcrumb_name(company), line_referential_company_path(company.line_referential, company)
  parent :companies, company.line_referential
end

crumb :networks do |line_referential|
  link I18n.t('networks.index.title'), line_referential_networks_path(line_referential)
  parent :line_referential, line_referential
end

crumb :network do |network|
  link breadcrumb_name(network), line_referential_network_path(network.line_referential, network)
  parent :networks, network.line_referential
end

crumb :group_of_lines do |line_referential|
  link I18n.t('group_of_lines.index.title'), line_referential_group_of_lines_path(line_referential)
  parent :line_referential, line_referential
end

crumb :group_of_line do |group_of_line|
  link breadcrumb_name(group_of_line), line_referential_group_of_line_path(group_of_line.line_referential, group_of_line)
  parent :group_of_lines, group_of_line.line_referential
end

crumb :lines do |line_referential|
  link I18n.t('lines.index.title'), line_referential_lines_path
  parent :line_referential, line_referential
end

crumb :line do |line|
  link breadcrumb_name(line), line_referential_line_path(line.line_referential, line)
  parent :lines, line.line_referential
end

crumb :purchase_windows do |referential|
  link I18n.t('purchase_windows.index.title'), referential_purchase_windows_path(referential)
  parent :referential, referential
end

crumb :purchase_window do |referential, purchase_window|
  link breadcrumb_name(purchase_window), referential_purchase_window_path(referential, purchase_window)
  parent :purchase_windows, referential
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

crumb :line_footnotes do |referential, line|
  link breadcrumb_name(line), referential_line_footnotes_path(referential, line)
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

crumb :referential_stop_areas do |referential|
  link I18n.t('stop_areas.index.title'), referential_stop_areas_path(referential)
  parent :referential, referential
end

crumb :referential_stop_area do |referential, stop_area|
  link breadcrumb_name(stop_area), referential_stop_area_path(referential, stop_area)
  parent :referential_stop_areas, referential
end

crumb :vehicle_journeys do |referential, route|
  link I18n.t('vehicle_journeys.index.title', route: route.name), referential_line_route_vehicle_journeys_path(referential, route.line, route)
  parent :route, referential, route
end

# crumb :compliance_controls do|compliance_control_sets|
#   link
#   parent :compliance_control_sets, compliance_control_sets
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).
