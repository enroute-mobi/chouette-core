class DayTypeInput < SimpleForm::Inputs::CollectionCheckBoxesInput
  # We assume that is input will be used for week_days column type which is a custom representation of a 7 bits string.
  # the relevant input is a hidden field that will send a 7 char string
  # each time a checkbox is (un)checked we update the value of the hidden field 
  def input
    raise "#{attribute_name} is not an instance of Timetable::DaysOfWeek" unless days_of_week.is_a?(Timetable::DaysOfWeek)

    content = ''

    content << @builder.hidden_field(attribute_name, value: string_value, 'x-model': 'stringValue') # relevant data is coming from this field

    collection.each_with_index.map do |(value, label), index|
      content << template.content_tag(:div, class: 'lcbx-group-item') do
        template.content_tag(:div, class: 'checkbox') do
          template.content_tag(:label) do
            template.concat @builder.check_box(attribute_name, checkbox_options(value), value, value)
            template.concat template.content_tag(:span, label, class: 'lcbx-group-item-label')
          end
        end
      end
    end
    
    template.content_tag(
      :div,
      content.html_safe,
      class: 'form-group labelled-checkbox-group',
      'x-data':  "{
        stringValue: '#{string_value}',
        binaryValue: #{binary_value},
        isChecked(v) { return Boolean(v & this.binaryValue) }
        }",
      'x-init': "$watch('binaryValue', v => stringValue = v.toString(2).padStart(7, '0'))"
    )
  end

  def checkbox_options(value)
    # We remove the name & the id of the checkbox because we do not want them to send data
    {
      name: nil,
      id: nil,
      'x-bind:checked': "isChecked(#{value})",
      '@change': "binaryValue ^= #{value}"
    }
  end

  def binary_value
    @binary_value ||= string_value.to_i(2)
  end

  def string_value
    @string_value ||= WeekDays.new.serialize(days_of_week)
  end

  def days_of_week
    @days_of_week ||= @builder.object.send(attribute_name)
  end

  private

=begin
  Private representation of each week day
  | Day       | Binary  | Integer   |
  |---------------------------------|
  | Monday    | '1000000' | 64      |
  | Tuesday   | '0100000' | 32      |
  | Wednesday | '0010000' | 16      |
  | Thursday  | '0001000' | 8       |
  | Friday    | '0000100' | 4       |
  | Saturday  | '0000010' | 2       |
  | Sunday    | '0000001' | 1       |
=end

  def collection
    Timetable::DaysOfWeek::SYMBOLIC_DAYS.each_with_index.map do |d, i|
      value = '0000000'
      value[i] = '1'
      [value.to_i(2),  Chouette::TimeTable.tmf(d)[0...2]]
    end
  end
end
