class TimePickerInput < SimpleForm::Inputs::Base
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input
    javascript_additional_packs 'inputs/date_picker'

    # Never update the code before read https://flatpickr.js.org/examples/#flatpickr--external-elements
    input_html_options[:type] = 'text'
    input_html_options[:data] ||= { 'input': ''}

    content_tag(:div, class: 'time_picker_block flex') do
      concat @builder.text_field(attribute_name, input_html_options)
      concat( content_tag(:div, class: 'flex items-center bg-enroute-blue rounded-tr-full rounded-br-full') do
        concat clock_button
      end)
    end
  end

  def input_html_classes
    super.push 'border border-gray-300 rounded-tl rounded-bl w-full py-4 px-3 focus:outline-none focus:ring-0 focus:border-blue-500 leading-6 transition-colors duration-200 ease-in-out string optional'
  end

  private

  def clock_button
    content_tag(:a, title: "toggle", class: 'btn btn-default color-danger', 'data-toggle': "time_picker") do
      concat content_tag(:i, "", class: 'far fa-clock')
    end
  end

end
