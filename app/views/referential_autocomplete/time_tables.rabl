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

attributes :comment, :objectid