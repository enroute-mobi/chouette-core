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
    Export::Base.user_visible_descendants.select{|e| workgroup.has_export? e.name}
  end

  def exports_metadatas(export)
    metadatas = { I18n.t("activerecord.attributes.export.type") => export.object.class.human_name }
    metadatas = metadatas.update({I18n.t("activerecord.attributes.export.status") => operation_status(export.status, verbose: true)})
    metadatas = metadatas.update({I18n.t("activerecord.attributes.export.referential") => export.referential.present? ? link_to(export.referential.name, [export.referential]) : "-" })
    metadatas = metadatas.update({I18n.t("activerecord.attributes.export.parent") => link_to(export.parent.name, [export.parent.workbench, export.parent])}) if export.parent.present?
    metadatas = metadatas.update Hash[*export.visible_options.map{|k, _v| [t("activerecord.attributes.export.#{export.object.class.name.demodulize.underscore}.#{k}"), display_option_value(export, k)]}.flatten]

    if export.children.any?
      files = export.children.map(&:file).select(&:present?)
      if files.any?
        metadatas = metadatas.update({I18n.t("activerecord.attributes.export.files") => ""})
        export.children.each do |e|
          metadatas = metadatas.update({"- #{e.class.human_name}" => e.file.present? ? link_to(e.file.file.filename, e.file.url) : "-"})
        end
      else
        metadatas = metadatas.update({I18n.t("activerecord.attributes.export.files") => "-"})
      end
    end

    metadatas
  end
end
