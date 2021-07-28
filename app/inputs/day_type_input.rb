class DayTypeInput < SimpleForm::Inputs::CollectionCheckBoxesInput

  def input(wrapper_options = nil)
    days_of_week = @builder.object.send(attribute_name)

    raise "#{attribute_name} is not an instance of Timetable::DaysOfWeek" unless days_of_week.is_a?(Timetable::DaysOfWeek)

    template.content_tag(:div, class: 'form-group labelled-checkbox-group') do
      @builder.collection_check_boxes(
        attribute_name,
        collection,
        :first,
        :last,
        {
          boolean_style: :inline,
          item_wrapper_tag: false,
          include_hidden: false
        }
      ) do |b|
        name = "#{@builder.object_name}[#{attribute_name}][#{b.value}]"
        checked = days_of_week.days.include?(b.value.to_sym)
        check_box_value = checked ? b.value : '.'

        options = {
          name: name,
          checked: checked,
          value: check_box_value
        }

        template.content_tag(:div, class: 'lcbx-group-item') do
          template.content_tag(:div, class: 'checkbox') do
            template.content_tag(:label) do
              template.concat @builder.check_box(attribute_name, options, b.value, '.')
              template.concat template.content_tag(:span, b.text, class: 'lcbx-group-item-label')
            end
          end
        end
      end
    end
  end

  private

  def collection
    Timetable::DaysOfWeek::SYMBOLIC_DAYS.map do |d|
      [d.to_s,  Chouette::TimeTable.tmf(d)[0...2]]
    end
  end
end