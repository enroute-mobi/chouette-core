describe "/layouts/application", :type => :view do

  let(:organisation){ create :organisation }
  let!(:workbench){ create :workbench, organisation: organisation}

  before(:each) do
    allow(view).to receive_messages :user_signed_in? => true
    allow(view).to receive_messages :current_organisation => organisation
    allow(Rails.application.config).to receive_messages :portal_url => "portal_url"
    allow(Rails.application.config).to receive_messages :codifligne_url => "codifligne_url"
    allow(Rails.application.config).to receive_messages :reflex_url => "reflex_url"
    workbench.workgroup.update export_types: ['Export::Gtfs']
  end

  it "should have menu items" do
    render
    expect(rendered).to have_menu_title 'layouts.navbar.current_offer.other'.t
    expect(rendered).to have_menu_link_to '/'
    expect(rendered).to have_menu_link_to workbench_output_path(workbench)

    expect(rendered).to have_menu_title 'activerecord.models.workbench.one'.t.capitalize
    expect(rendered).to have_menu_link_to workbench_path(workbench)
    expect(rendered).to have_menu_link_to workbench_imports_path(workbench)
    expect(rendered).to have_menu_link_to workbench_exports_path(workbench)
    expect(rendered).to have_menu_link_to workbench_calendars_path(workbench)

    expect(rendered).to have_menu_title('layouts.navbar.line_referential'.t)
    expect(rendered).to have_menu_link_to workbench_line_referential_lines_path(workbench)
    expect(rendered).to have_menu_link_to workbench_line_referential_networks_path(workbench)
    expect(rendered).to have_menu_link_to workbench_line_referential_companies_path(workbench)

    expect(rendered).to have_menu_title 'layouts.navbar.stop_area_referential'.t
    expect(rendered).to have_menu_link_to workbench_stop_area_referential_stop_areas_path(workbench)

    expect(rendered).to have_menu_title 'layouts.navbar.configuration'.t
    expect(rendered).to_not have_menu_link_to edit_workbench_path(workbench)
    expect(rendered).to_not have_menu_link_to edit_workgroup_path(workbench.workgroup)
  end
end
