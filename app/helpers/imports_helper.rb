# -*- coding: utf-8 -*-
module ImportsHelper

  # Import statuses helper
  def import_status(status, verbose: false, default_status: nil)
    status ||= default_status
    return unless status
    status = status.to_s.downcase
    out = if %w[new running pending].include? status
      content_tag :span, '', class: "fa fa-clock-o"
    else
      cls =''
      cls = 'success' if status == 'successful'
      cls = 'success' if status == 'ok'
      cls = 'warning' if status == 'warning'
      cls = 'danger' if %w[failed aborted canceled error].include? status

      content_tag :span, '', class: "fa fa-circle text-#{cls}"
    end
    if verbose
      out += content_tag :span do
        txt = "imports.status.#{status}".t(fallback: "")
      end
    end
    out
  end

  # Compliance check set messages
  def bootstrap_class_for_message_criticity message_criticity
    case message_criticity.downcase
      when "error", "aborted"
        "alert alert-danger"
      when "warning"
        "alert alert-warning"
      when "info"
        "alert alert-info"
      when "ok", "success"
        "alert alert-success"
      else
        message_criticity.to_s
    end
  end

  def import_message_content message
    export_message_content message
  end
end
