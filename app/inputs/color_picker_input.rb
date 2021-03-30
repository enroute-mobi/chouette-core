class ColorPickerInput < SimpleForm::Inputs::Base

  def input(wrapper_options = {})
    template.content_tag(:div, class: 'input-group colorpicker-component enhanced_color_picker') do
      template.concat "<span class='input-group-addon pickerInput'><i></i></span>".html_safe
      template.concat @builder.text_field(attribute_name, input_html_options)
    end
  end

  def input_html_options
    selected_color = object.send(attribute_name)
    super.merge({class: 'hexInput form-control', type: 'text', value: selected_color})
  end
end
