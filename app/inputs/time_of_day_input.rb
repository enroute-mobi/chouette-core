# frozen_string_literal: true

class TimeOfDayInput < SimpleForm::Inputs::Base
  delegate :select_hour, :select_minute, to: :template

  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    [
      select_hour(time_of_day, hour_options, merged_input_options),
      select_minute(time_of_day, minute_options, merged_input_options),
      select_day_offset(time_of_day, day_offset_options, merged_input_options)
    ].compact.join(content_tag(:span, " : ", class: 'mx-5'))
  end

  def select_day_offset(time_of_day, options = {}, html_options = {})
    return nil unless html_options[:use_day_offset]

    SelectDayOffset.new(time_of_day, options, html_options).select_day_offset
  end

  class SelectDayOffset < ActionView::Helpers::DateTimeSelector
    def time_of_day
      @datetime
    end

    def day_offset
      time_of_day&.day_offset
    end

    def select_day_offset
      if @options[:use_hidden] || @options[:discard_day_offset]
        build_hidden(:day_offset, day_offset || 0)
      else
        build_select(:day_offset, build_day_offset_options(day_offset))
      end
    end

    def build_day_offset_options(selected)
      select_options = []
      (0..5).each do |value|
        tag_options = { value: value }
        tag_options[:selected] = "selected" if selected == value
        text = day_offset_name(value)
        select_options << content_tag("option", text, tag_options)
      end

      (select_options.join("\n") + "\n").html_safe
    end

    def day_offset_name(number)
      "J+#{number}"
    end
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

  def day_offset_options
    base_options.merge(field_name: attribute_name_with_position(3))
  end

  def time_of_day
    @time_of_day ||= @builder.object.send(attribute_name)
  end
end
