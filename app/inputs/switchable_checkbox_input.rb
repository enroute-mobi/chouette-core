class SwitchableCheckboxInput < SimpleForm::Inputs::BooleanInput
  def input
    template.content_tag(:div, class: 'onoffswitch') do
      template.concat @builder.check_box(attribute_name, input_html_options)
      template.concat false_input
    end
  end

  def input_html_options
    super.merge(class: 'onoffswitch-checkbox', id: attribute_name)
  end

  def span_inner
    template.content_tag(:span, '', class: 'onoffswitch-inner')
  end

  def span_switch
    template.content_tag(:span, '', class: 'onoffswitch-switch')
  end

  def false_input
    template.content_tag(:label, class: 'onoffswitch-label', for: attribute_name) do
      template.concat span_inner
      template.concat span_switch
    end
  end

  def checked?
    object.send(attribute_name).present?
  end
end
