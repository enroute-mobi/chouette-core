class TimePickerInput < SimpleForm::Inputs::Base
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input
    javascript_additional_packs 'inputs/date_picker'

    # Never update the code before read https://flatpickr.js.org/examples/#flatpickr--external-elements
    input_html_options[:type] = 'text'
    input_html_options[:data] ||= { 'input': ''}
    input_html_options[:style] = 'background-color: white;'
    
    content_tag(:div, class: 'time_picker input-group') do
      concat @builder.text_field(attribute_name, input_html_options)
      concat( content_tag(:div, class: 'input-group-btn') do
        concat clock_button
      end)
    end
  end

  def input_html_classes
    super.push 'form-control'
  end

  private

  def clock_button
    content_tag(:a, title: "toggle", class: 'btn btn-default color-danger', 'data-toggle': "time_picker") do
      concat content_tag(:i, "", class: 'far fa-clock')
    end
  end

end
