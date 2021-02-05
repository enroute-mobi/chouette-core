class ClockpickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options = {})
    template.content_tag(:div, class: 'input-group clockpicker col-sm-2') do
      template.concat @builder.text_field(attribute_name, input_html_options)
      template.concat span_remove
    end
  end

  def input_html_options
    super.merge(class: 'form-control')
  end

  def span_remove
    template.content_tag(:span, class: 'input-group-addon') do
      template.concat "<i class='fa fa-clock'></i>".html_safe
    end
  end
end
