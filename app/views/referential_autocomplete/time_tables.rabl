collection @time_tables

node do |time_table|
  {
    id: time_table.id,
    text: "<strong><span class='fa fa-circle' style='color:" + (time_table.color || '#4b4b4b') + "'></span> " + time_table.comment + ' - ' + time_table.get_objectid.short_id + '</strong><br/><small>' + time_table.display_day_types + '</small>'
  }
end
