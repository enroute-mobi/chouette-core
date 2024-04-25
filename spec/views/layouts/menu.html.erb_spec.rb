# frozen_string_literal: true

describe '/layouts/application', type: :view do
  before(:each) do
    allow(Rails.application.config).to receive_messages portal_url: 'portal_url'
    allow(Rails.application.config).to receive_messages codifligne_url: 'codifligne_url'
    allow(Rails.application.config).to receive_messages reflex_url: 'reflex_url'
    current_workbench.workgroup.update export_types: ['Export::Gtfs']
  end

  it 'should have menu items' do
    render
    expect(rendered).to have_menu_link_to '/'
    expect(rendered).to have_menu_link_to workbench_output_path(current_workbench)

    expect(rendered).to have_menu_title Workbench.model_name.human.capitalize
    expect(rendered).to have_menu_link_to workbench_path(current_workbench)
    expect(rendered).to have_menu_link_to workbench_imports_path(current_workbench)
    expect(rendered).to have_menu_link_to workbench_exports_path(current_workbench)
    expect(rendered).to have_menu_link_to workbench_calendars_path(current_workbench)

    expect(rendered).to have_menu_title LineReferential.model_name.human
    expect(rendered).to have_menu_link_to workbench_line_referential_lines_path(current_workbench)
    expect(rendered).to have_menu_link_to workbench_line_referential_networks_path(current_workbench)
    expect(rendered).to have_menu_link_to workbench_line_referential_companies_path(current_workbench)

    expect(rendered).to have_menu_title StopAreaReferential.model_name.human
    expect(rendered).to have_menu_link_to workbench_stop_area_referential_stop_areas_path(current_workbench)

    expect(rendered).to have_menu_title I18n.t('layouts.navbar.configuration')
    expect(rendered).to_not have_menu_link_to edit_workgroup_path(current_workbench.workgroup)
  end
end
