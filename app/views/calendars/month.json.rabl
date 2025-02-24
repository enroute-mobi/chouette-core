object @calendar

node do |tt|
  {
    name: I18n.l(@date, format: '%B'),
    days: tt.month_inspect(@date),
    day_types: %w(monday tuesday wednesday thursday friday saturday sunday).select{ |d| tt.send(d) }.map{ |d| tt.human_attribute_name(d).first(2)}.join('')
  }
end
