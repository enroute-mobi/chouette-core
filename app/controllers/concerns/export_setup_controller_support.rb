# frozen_string_literal: true

module ExportSetupControllerSupport
  def parse_export_setup_netex_profile_options!(params, export_type_attribute, export_setup_attribute)
    return unless params[export_type_attribute] == 'Export::NetexGeneric'
    return unless params[export_setup_attribute] && params[export_setup_attribute][:profile_options]

    params[export_setup_attribute][:profile_options] = Hash[
      params[export_setup_attribute][:profile_options].values.map { |v| [v['key'], v['value']] }
    ]
  end
end
