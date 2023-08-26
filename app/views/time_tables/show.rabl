object @time_table

attributes :id, :comment
node do |tt|
  {
    time_table_bounding: tt.presenter.time_table_bounding,
    day_types: %w(monday tuesday wednesday thursday friday saturday sunday).select{ |d| tt.send(d) }.map{ |d| tt.human_attribute_name(d).first(2)}.join(''),
    current_month: tt.month_inspect(Date.today),
    periode_range: month_periode_enum(tt.bounding_dates, 5),
    current_periode_range: tt.bounding_dates.first&.beginning_of_month || Date.today.beginning_of_month,
    color: tt.color ? tt.color : '',
    short_id: tt.get_objectid.short_id
  }
end

child(:periods, object_root: false) do
  attributes :id, :period_start, :period_end
end

child(:dates, object_root: false) do
  attributes :id, :date, :in_out
end

child(:calendar) do
  attributes :id, :name
end
