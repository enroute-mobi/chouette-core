class DayTypeInput < SimpleForm::Inputs::CollectionCheckBoxesInput
  # We assume that is input will be used for week_days column type which is a custom representation of a 7 bits string.
  # the relevant input is a hidden field that will send a 7 char string
  # each time a checkbox is (un)checked we update the value of the hidden field 
  def input
    raise "#{attribute_name} is not an instance of Timetable::DaysOfWeek" unless days_of_week.is_a?(Timetable::DaysOfWeek)

    content = ''

    content << @builder.hidden_field(attribute_name, value: default_value, ':value': 'value') # relevant data is coming from this field

    collection.each_with_index.map do |(value, label), index|
      content << template.content_tag(:div, class: 'lcbx-group-item') do
        template.content_tag(:div, class: 'checkbox') do
          template.content_tag(:label) do
            template.concat @builder.check_box(attribute_name, checkbox_options(value, index))
            template.concat template.content_tag(:span, label, class: 'lcbx-group-item-label')
          end
        end
      end
    end
    
    template.content_tag(:div, content.html_safe, class: 'form-group labelled-checkbox-group', 'x-data': x_data)
  end

  def x_data
    "{
      value: '#{default_value}', 
      handleChange(e) {
        const { checked, dataset: { index } } = e.target
        const coll = this.value.split('')
        coll[index] = checked ? '1' : '0'

        this.value = coll.join('')
      }
    }"
  end

  def checkbox_options(value, index)
    # We remove the name & the id of the checkbox because we do not want them to send data
    {
      name: nil,
      id: nil,
      checked: days_of_week.days.include?(value.to_sym),
      'data-index': index,
      'x-on:change': 'handleChange' # update the hidden field value on change
    }
  end

  def default_value
    WeekDays.new.serialize(days_of_week)
  end

  def days_of_week
    @days_of_week ||= @builder.object.send(attribute_name)
  end

  private

  def collection
    Timetable::DaysOfWeek::SYMBOLIC_DAYS.map do |d|
      [d.to_s,  Chouette::TimeTable.tmf(d)[0...2]]
    end
  end
end