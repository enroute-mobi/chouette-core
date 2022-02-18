object @calendar

attributes :id
node do |tt|
  {
    comment: tt.name,
    shared: tt.shared,
    time_table_bounding: tt.presenter.time_table_bounding,
    day_types: %w(monday tuesday wednesday thursday friday saturday sunday).select{ |d| tt.send(d) }.map{ |d| tt.human_attribute_name(d).first(2)}.join(''),
    current_month: tt.month_inspect(Date.today),
    periode_range: month_periode_enum(tt.bounding_dates, 5),
    current_periode_range: Date.today.beginning_of_month,
    short_id: tt.object_id,
    shared: tt.shared
  }
end

child(:periods, object_root: false, root: :time_table_periods) do
  attributes :id, :period_start, :period_end
end

child(:all_dates, object_root: false, root: :time_table_dates) do
  attributes :id, :date, :in_out
end
