class TimePickerInput < SimpleForm::Inputs::Base
  def input
    set_html_options

    template.content_tag(:div, class: 'time_picker input-group') do
      template.concat @builder.text_field(attribute_name, input_html_options)
      template.concat( template.content_tag(:div, class: 'input-group-btn') do
        template.concat clock_button
      end)
    end
  end

  def input_html_classes
    super.push 'form-control'
  end

  private

  def clock_button
    template.content_tag(:a, title: "toggle", class: 'btn btn-default color-danger', 'data-toggle': "") do
      template.concat template.content_tag(:i, "", class: 'far fa-clock')
    end
  end

  def set_html_options
    input_html_options[:type] = 'text'
    input_html_options[:data] ||= { 'input': ''}
    # input_html_options[:data].merge!(date_options: date_options)
  end
end