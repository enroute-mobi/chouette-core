
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
    if object.instance_of?(Workbench)
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
    content_for(:page_header_title) || (defined?(resource_class) ? resource_class.t_action(params[:action]) : nil)
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

  def polymorphic_path_patch( source)
    relative_url_root = Rails.application.config.relative_url_root
    relative_url_root && !source.starts_with?("#{relative_url_root}/") ? "#{relative_url_root}#{source}" : source
  end

  def assets_path_patch( source)
    relative_url_root = Rails.application.config.relative_url_root
    return "/assets/#{source}" unless relative_url_root
    "#{relative_url_root}/assets/#{source}"
  end

  def cancel_button(cancel_path = :back)
    link_to t('cancel'), cancel_path, method: :get, class: 'btn btn-cancel formSubmitr', data: {:confirm =>  t('cancel_confirm')}
  end

  def link_to_if_table condition, label, url
     condition == false ? label = '-' : label
     link_to_if(condition, label, url)
  end
end
