class DatePickerInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    javascript_additional_packs 'inputs/date_picker'

    # Never update the code before read https://flatpickr.js.org/examples/#flatpickr--external-elements
    input_html_options[:type] = 'text'
    input_html_options[:data] = { 'input': ''}
    input_html_options[:value] ||= I18n.localize(value, format: display_pattern) if value

    content_tag(:div, class: 'date_picker_block flex') do
      concat @builder.text_field(attribute_name, input_html_options)
      concat( content_tag(:div, class: 'flex items-center bg-enroute-blue rounded-tr-full rounded-br-full') do
        concat calendar_button
        concat clear_button
      end)
    end

  end

  def input_html_classes
    super.push 'border border-gray-300 rounded-tl rounded-bl w-full py-4 px-3 focus:outline-none focus:ring-0 focus:border-blue-500 leading-6 transition-colors duration-200 ease-in-out string optional'
  end

  private

  def clear_button
    content_tag(:a, title: "clear", class: 'btn btn-default ml-0', 'data-clear': "") do
      concat content_tag(:i, "", class: 'fas fa-times')
    end
  end

  def calendar_button
    content_tag(:a, title: "toggle", class: 'btn btn-default color-danger', 'data-toggle': "") do
      concat content_tag(:i, "", class: 'far fa-calendar')
    end
  end

  def value
    object.send(attribute_name) if object.respond_to? attribute_name
  end

  def display_pattern
    I18n.t('datepicker.dformat', default: '%d/%m/%Y')
  end

  # def picker_pattern
  #   I18n.t('datepicker.pformat', default: 'DD/MM/YYYY')
  # end
  #
  # def date_options_base
  #   {
  #       locale: I18n.locale.to_s,
  #       format: picker_pattern,
  #   }
  # end
  #
  # def date_options
  #   custom_options = input_html_options[:data][:date_options] || {}
  #   date_options_base.merge!(custom_options)
  # end

end
