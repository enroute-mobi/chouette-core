# -*- coding: utf-8 -*-
module ImportsHelper

  # Compliance check set messages
  def bootstrap_class_for_message_criticity(message_criticity)
    case message_criticity.downcase
    when 'error', 'aborted'
      'alert alert-danger'
    when 'warning'
      'alert alert-warning'
    when 'info'
      'alert alert-info'
    when 'ok', 'success'
      'alert alert-success'
    else
      message_criticity.to_s
    end
  end

  def import_message_content(message)
    export_message_content message
  end

  def import_controls(workbench)
    workbench.workgroup.import_compliance_control_sets.map do |key, label|
      TableBuilderHelper::Column.new(
        name: label,
        attribute: proc do |n|
          if n.workbench.compliance_control_set(key).present?
            operation_status(
              n.workbench_import_check_set(key)&.status,
              verbose: true,
              default_status: (n.status == "ERROR" ? :aborted : :pending)
            )
          else
            '-'
          end
        end,
        sortable: false,
        link_to: lambda do |item|
          item.workbench_import_check_set(key).present? && if @workbench == @import.workbench
            [@import.workbench, item.workbench_import_check_set(key)]
          else
            [@import.workbench.workgroup, item.workbench_import_check_set(key)]
          end
        end
      )
    end
  end

  def import_metadatas(import)
    metadata = {}
    metadata.update({ t('imports.show.filename') => @import.try(:file_identifier) }) if @import.is_a?(Import::Workbench)
    metadata.update({ t('imports.show.status') => operation_status(@import.status, verbose: true) })
    if @import.referential.present?
      metadata = metadata.update({ t('imports.show..referential') => link_to_if_i_can(@import.referential.name, @import.referential) })
    end
    metadata = metadata.update({ Workbench.ts.capitalize => link_to_if_i_can(@import.workbench.organisation.name, @import.workbench) }) unless @workbench
    metadata = metadata.update Hash[*@import.visible_options.map{|k, v| [t("activerecord.attributes.import.#{@import.object.class.name.demodulize.underscore}.#{k}"), @import.display_option_value(k, self)]}.flatten]
    metadata = metadata.update({ Import::Base.tmf(:notification_target) => I18n.t("operation_support.notification_targets.#{@import.notification_target || 'none'}") })
    metadata
  end
end
