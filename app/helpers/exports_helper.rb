# -*- coding: utf-8 -*-
module ExportsHelper
  def export_status status
    import_status status
  end

  def export_option_input form, export, attr, option_def, type
    opts = { required: option_def[:required], input_html: {value: export.try(attr) || option_def[:default_value]}, as: option_def[:type], selected:  export.try(attr) || option_def[:default_value]}
    opts[:collection] = option_def[:collection] if option_def.has_key?(:collection)
    opts[:collection] = export.instance_exec(&option_def[:collection]) if option_def[:collection].is_a?(Proc)
    opts[:label] = t "activerecord.attributes.export.#{type.name.demodulize.underscore}.#{attr}"
    form.input attr, opts
  end

  def export_message_content message
    if message.message_key == "full_text"
      message.message_attributes["text"]
    else
      t([message.class.name.underscore.gsub('/', '_').pluralize, message.message_key].join('.'), message.message_attributes&.symbolize_keys || {})
    end.html_safe
  end

  def workgroup_exports workgroup
    Export::Base.user_visible_descendants.select{|e| workgroup.has_export? e.name}
  end
end
