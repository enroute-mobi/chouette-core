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
end
