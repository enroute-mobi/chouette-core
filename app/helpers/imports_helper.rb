# -*- coding: utf-8 -*-
module ImportsHelper

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
end
