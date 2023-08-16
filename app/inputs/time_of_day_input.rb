# frozen_string_literal: true

class TimeOfDayInput < SimpleForm::Inputs::Base
  delegate :select_hour, :select_minute, to: :template

  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper

  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    parts = [
      select_hour(time_of_day, hour_options, merged_input_options),
      separator(':'),
      select_minute(time_of_day, minute_options, merged_input_options)
    ]

    parts += [separator, select_day_offset(merged_input_options)] if use_day_offset?

    parts.join
  end

  def select_day_offset(html_options = {})
    options = options_from_collection_for_select(day_offsets, 'value', 'name', time_of_day&.day_offset || 0)
    select_tag "#{object_name}[#{attribute_name_with_position(4)}]", options, html_options
  end

  def use_day_offset?
    options[:use_day_offset]
  end

  def day_offsets
    (0..5).map { |value| DayOffset.new(value) }
  end

  def separator(content = '')
    content_tag(:span, content, class: 'mx-3')
  end

  class DayOffset
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def name
      I18n.t('day_offset.name', value: value)
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

  def time_of_day
    @time_of_day ||= @builder.object.send(attribute_name)
  end
end
