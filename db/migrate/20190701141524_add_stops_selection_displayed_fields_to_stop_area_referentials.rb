class AddStopsSelectionDisplayedFieldsToStopAreaReferentials < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_area_referentials, :stops_selection_displayed_fields, :jsonb, default: {objectid: true}
    end
  end
end
