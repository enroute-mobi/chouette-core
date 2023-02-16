
# coding: utf-8
module ApplicationHelper

  include NewapplicationHelper

  def array_to_html_list items
    content_tag :ul do
      items.each do |item|
        concat content_tag :li, item
      end
    end
  end

  def page_header_resource_name(object)
    return content_for(:page_header_resource_name) if content_for?(:page_header_resource_name)
    resource_class.ts.capitalize
  end

  def page_header_title(object)
    # Unwrap from decorator, we want to know the object model name
    return content_for(:page_header_title) if content_for?(:page_header_title)
    object = object.object if object.decorated?

    local = "#{object.model_name.name.underscore.pluralize}.#{params[:action]}.title"

    if object.respond_to?(:name)
      user_identifier = %i{objectid uuid short_name id}.map { |m| object.try(m) }.find(&:itself)
      t(local, name: object.name || user_identifier)
    else
      t(local)
    end
  end

  def page_header_meta(object)
    out = ""
    display = true
    if policy(object).respond_to?(:synchronize?)
      display = policy(object).synchronize?
    elsif object.instance_of?(Workbench)
      display = false
    end

    if display
      info = t('last_update', time: l(object.updated_at))
      if object.try(:has_metadata?)
        author = object.metadata.modifier_username || t('default_whodunnit')
        info = safe_join([info, tag(:br), t('whodunnit', author: author)])
      end
      out = content_tag :div, info, class: 'small last-update'
    end
    out
  end

  def page_title
    title = t('brandname')
    t = content_for(:page_header_title) || (defined?(resource_class) ? resource_class.t_action(params[:action]) : nil)
    title += " | #{t}" if t
  end

  def page_header_content_for(object)
    content_for :page_header_resource_name, page_header_resource_name(object)
    content_for :page_header_title, page_header_title(object)
    content_for :page_header_meta, page_header_meta(object)
  end

  def font_awesome_classic_tag(name)
    name = "fa-file-text-o" if name == "fa-file-csv-o"
    name = "fa-file-code-o" if name == "fa-file-xml-o"
    content_tag(:i, nil, {class: "fa #{name}"})
  end

  def selected_referential?
    @referential.present? and not @referential.new_record?
  end

  def format_restriction_for_locales(referential)
    if !referential.respond_to?(:data_format) or referential.data_format.blank?
      ""
    else
      "."+referential.data_format
    end
  end

  def polymorphic_path_patch( source)
    relative_url_root = Rails.application.config.relative_url_root
    relative_url_root && !source.starts_with?("#{relative_url_root}/") ? "#{relative_url_root}#{source}" : source
  end

  def assets_path_patch( source)
    relative_url_root = Rails.application.config.relative_url_root
    return "/assets/#{source}" unless relative_url_root
    "#{relative_url_root}/assets/#{source}"
  end

  def help_page?
    controller_name == "help"
  end

  def help_path
    path = request.env['PATH_INFO']
    target = case
    when path.include?("/help")
      ""
    when path.include?("/networks")
      "networks"
    when path.include?("/companies")
      "companies"
    when path.include?("/group_of_lines")
      "group_of_lines"
    when path.include?("/vehicle_journeys")
      "vehicle_journeys"
    when path.include?("/vehicle_journey_frequencies")
      "vehicle_journeys"
    when path.include?("/journey_patterns")
      "journey_patterns"
    when path.include?("/routes")
      "routes"
    when path.include?("/lines")
      "lines"
    when path.include?("/stop_areas")
      "stop_areas"
    when path.include?("/time_tables")
      "time_tables"
    when path.include?("/exports")
      "exports"
    when path.include?("/compliance_check_tasks")
      "validations"
    when path.include?("/referentials")
      "dataspaces"
    else
      ""
    end

    url_for(:controller => "/help", :action => "show") + '/' + target
  end

  def permitted_custom_fields_params custom_fields
    res = [{
      custom_field_values: custom_fields.map(&:code)
    }]
    custom_fields.where(field_type: :attachment).each do |cf|
      res << "remove_custom_field_#{cf.code}"
    end
  res
  end

  def cancel_button(cancel_path = :back)
    link_to t('cancel'), cancel_path, method: :get, class: 'btn btn-cancel formSubmitr', data: {:confirm =>  t('cancel_confirm')}
  end

  def link_to_if_i_can label, url, object: nil, permission: :show
    object ||= url
    object = object.last if object.is_a?(Array)

    if object && Pundit.policy(UserContext.new(current_user), object) && Pundit.policy(UserContext.new(current_user), object).send("#{permission}?")
      link_to label, url
    else
      label
    end
  end

  def link_to_if_table condition, label, url
     condition == false ? label = '-' : label
     link_to_if(condition, label, url)
  end
end
