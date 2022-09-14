# frozen_string_literal: true

class TimeOfDayInput < SimpleForm::Inputs::Base
  delegate :select_hour, :select_minute, to: :template

  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    select_hour(time_of_day, hour_options, merged_input_options) 
      + content_tag(:span, " : " )
      + select_minute(time_of_day, minute_options, merged_input_options)
  end

  def base_options
    { prefix: object_name }
  end

  def attribute_name_with_position(position)
    "#{attribute_name}(#{position}i)"
  end

  def hour_options
    base_options.merge(field_name: attribute_name_with_position(1))
  end

  def minute_options
    base_options.merge(field_name: attribute_name_with_position(2), minute_step: 5)
  end

  def time_of_day
    @time_of_day ||= @builder.object.send(attribute_name)
  end

end
