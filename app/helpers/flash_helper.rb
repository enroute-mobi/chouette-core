module FlashHelper

  def bootstrap_class_for flash_type
    case flash_type
      when "success", "notice"
        "alert-success"
      when "error", "alert"
        "alert-danger"
      when "warning"
        "alert-warning"
      else
        flash_type.to_s
    end
  end

  def flash_message_for(flash_type, message)
    case flash_type
      when :success
        "<i class='fa fa-check-circle'></i>  #{message}".html_safe
      when :error
        "<i class='fa fa-minus-circle'></i> #{message}".html_safe
      when :alert
        "<i class='fa fa-exclamation-circle'></i> #{message}".html_safe
      when :notice
        "<i class='fa fa-info-circle'></i> #{message}".html_safe
      else
        message
    end
  end

  def flash_icon_for(flash_type)
    case flash_type
    when 'warning' then 'fa-exclamation-triangle'
    else
      'fa-exclamation-circle'
    end
  end

  def display_flash_message(flash_type, message)
    content_tag(:div, '', class: "alert #{bootstrap_class_for(flash_type)} alert-dismissible", role: 'alert') do
      concat  content_tag(:button, "<span class='fa fa-times-circle' aria-hidden='true'> </span>".html_safe, class: 'close', type: 'button', "data-dismiss": "alert", "aria-label": "Fermer")
      concat content_tag(:span, '', class: "fas fa-lg #{flash_icon_for(flash_type)}")
      concat content_tag(:span, message)
    end
  end

end
