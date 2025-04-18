class ExportDecorator < Af83::Decorator
  decorates Export::Base

  set_scope { context[:parent] }

  define_instance_method :export_status_css_class do
    cls = ''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  create_action_link if: -> { context[:parent].is_a?(Workbench) }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link primary: :show do |l|
      l.content { I18n.t('actions.download') }
      l.icon :download
      l.href   { [:download, scope, object] }
      l.disabled { !object.file.present? }
      l.download { [:download, scope, object] }
      l.target :blank
    end
  end

  define_instance_method :display_selected_lines_to_export do
    object.workgroup.line_referential.lines.where(id: object.line_ids).limit(15).pluck(:name).join(", ")
  end

  define_instance_method :display_profile_options do
    displayed_profile_options = ""
    object.profile_options.each_pair do |key, value|
      displayed_profile_options += ", " if displayed_profile_options.present?
      displayed_profile_options += "#{key} : #{value}"
    end
    displayed_profile_options
  end

  define_instance_method :display_period do
    return "#{I18n.l(from, format: :default)} - #{I18n.l(to, format: :default)}" if(respond_to?(:from) && respond_to?(:to) && from.present? && to.present?)
    return "#{I18n.t('enumerize.period.only_next_days')} :  #{duration}" if duration.present?
    I18n.t('enumerize.period.all_periods')
  end

  define_instance_method :display_profile do
    I18n.t("enumerize.profile.#{profile}")
  end

  define_instance_method :display_code_space do
    return unless object.try(:exported_code_space)

    object.workgroup.code_spaces.find_by(id: object.exported_code_space)&.to_label
  end

  define_instance_method :line_ids_options do
    return [] unless object.line_ids

    Rabl::Renderer.new('autocomplete/lines', Chouette::Line.where(id: object.line_ids), format: :hash, view_path: 'app/views').render
  end

  define_instance_method :company_ids_options do
    return [] unless object.company_ids

    Rabl::Renderer.new('autocomplete/companies', Chouette::Company.where(id: object.company_ids), format: :hash, view_path: 'app/views').render
  end

  define_instance_method :line_provider_ids_options do
    return [] unless object.line_provider_ids

    Rabl::Renderer.new('autocomplete/line_providers', LineProvider.where(id: object.line_provider_ids), format: :hash, view_path: 'app/views').render
  end

  define_instance_method :pretty_print_options do
    options = {}

    add_option = -> (attribute_name, value) do
      key = object.class.human_attribute_name(attribute_name)
      options[key] = value.presence || '-'
    end

    add_option.call(:duration, display_period)
    add_option.call(:exported_lines, display_selected_lines_to_export)
    add_option.call(:profile, display_profile) if object.is_a?(Export::NetexGeneric)

    if object.is_a?(Export::Gtfs)
      add_option.call(:prefer_referent_stop_area, I18n.t(prefer_referent_stop_area))
    end

    options.map { |k, v| "#{k} : #{v}"}.join('<br/>').html_safe
  end

  define_instance_method :alpine_state do |is_export|
    initial_state = { referentialId: object.referential_id, isExport: is_export, type: object.type || 'Export::Gtfs' }

    object.options.reduce(initial_state) do |result, (k, v)|
      result[k.camelcase(:lower)] = v

      result
    end.to_json
  end

end
