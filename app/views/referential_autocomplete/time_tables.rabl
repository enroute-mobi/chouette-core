collection @time_tables

extends(
  'autocomplete/base',
  locals: {
    label_method: Proc.new do |tt|
      "<strong><span class='fa fa-circle' style='color:" + (tt.color ? tt.color : '#4b4b4b') + "'></span> " + tt.comment + " - " + tt.get_objectid.short_id + "</strong><br/><small>" + tt.display_day_types + "</small>"
    end
  }
)

node do |time_table|
  {
    :comment => time_table.comment,
    :objectid => time_table.objectid,
    :time_table_bounding => time_table.presenter.time_table_bounding,
    :composition_info => time_table.presenter.composition_info,
    :tags => time_table.tags.join(','),
    :color => time_table.color,
    :day_types => time_table.display_day_types,
    :short_id => time_table.get_objectid.short_id
  }
end
