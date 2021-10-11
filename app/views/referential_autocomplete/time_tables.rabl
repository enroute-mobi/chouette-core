collection @time_tables

extends(
  'autocomplete/base',
  locals: {
    label_method: Proc.new do |tt|
      is_purchase_window = tt.objectid.include?('PurchaseWindow')
      color = tt.color ? (is_purchase_window ? "##{tt.color}" : tt.color) : '#4B4B4B'

      '<strong>' + "<span class='fa fa-circle' style='color" + color + "'></span> " + (tt.comment || tt.name) + ' - ' + tt.get_objectid.short_id + '</strong>'
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
    :short_id => time_table.get_objectid.short_id,
  }
end
