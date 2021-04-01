class SwitchableCheckboxInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = {})
    template.content_tag(:div, class: 'onoffswitch') do
      template.concat @builder.check_box(attribute_name, input_html_options, checked_value, unchecked_value)
      template.concat false_input
    end
  end

  def input_id
    # There must be a cleaner way, I just cannot find it
    key = @builder.object_name.to_s.gsub(/[\]\[]/, '_').squeeze('_')
    "#{key}_#{reflection_or_attribute_name}"
  end

  def input_html_options
    super.merge(class: 'onoffswitch-checkbox', id: input_id)
  end

  def span_inner
    template.content_tag(:span, '', class: 'onoffswitch-inner', on: I18n.t("simple_form.yes"), off: I18n.t("simple_form.no"))
  end

  def span_switch
    template.content_tag(:span, '', class: 'onoffswitch-switch')
  end

  def false_input
    template.content_tag(:label, class: 'onoffswitch-label', for: input_id) do
      template.concat span_inner
      template.concat span_switch
    end
  end

  def checked?
    object.send(attribute_name).present?
  end

  def checked_value
    options.fetch(:checked_value, 'true')
  end

  def unchecked_value
    options.fetch(:unchecked_value, 'false')
  end
end
