# -*- coding: utf-8 -*-
module ExportsHelper

  def export_message_content message
    if message.message_key == "full_text"
      message.message_attributes["text"]
    else
      t([message.class.name.underscore.gsub('/', '_').pluralize, message.message_key].join('.'), message.message_attributes&.symbolize_keys || {})
    end.html_safe
  end

  def workgroup_exports workgroup
    workgroup.export_types.map(&:constantize)
  end

end
