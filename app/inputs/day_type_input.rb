class DayTypeInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  def input(wrapper_options = nil)
    days_of_week = @builder.object.send(attribute_name)
    value = WeekDays.new.serialize(days_of_week)

    raise "#{attribute_name} is not an instance of Timetable::DaysOfWeek" unless days_of_week.is_a?(Timetable::DaysOfWeek)

    content = ''

    content << @builder.hidden_field(attribute_name, value: value, ':value': 'value')

    collection.each_with_index.map do |(value, label), index|
      name = "#{@builder.object_name}[#{attribute_name}][#{value}]"
      checked = days_of_week.days.include?(value.to_sym)

      options = {
        name: nil,
        id: nil,
        checked: checked,
        value: checked ? '1' : '0',
        'data-index': index,
        'x-on:change': 'handleChange'
      }

      content << template.content_tag(:div, class: 'lcbx-group-item') do
        template.content_tag(:div, class: 'checkbox') do
          template.content_tag(:label) do
            template.concat @builder.check_box(attribute_name, options, '1', '0')
            template.concat template.content_tag(:span, label, class: 'lcbx-group-item-label')
          end
        end
      end
    end
    
    template.content_tag(
      :div,
      content.html_safe,
      class: 'form-group labelled-checkbox-group',
      'x-data': "{
        value: '#{value}', 
        handleChange(e) {
          const { checked, dataset: { index } } = e.target
          const coll = this.value.split('')
          coll[index] = checked ? '1' : '0'

          this.value = coll.join('')
          console.log('value', this.value)
        }
      }"
    )
  end

  private

  def collection
    Timetable::DaysOfWeek::SYMBOLIC_DAYS.map do |d|
      [d.to_s,  Chouette::TimeTable.tmf(d)[0...2]]
    end
  end
end